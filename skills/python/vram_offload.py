#!/usr/bin/env python3
"""
VRAM matrix offload — episode fingerprints → FSOT-GPU consensus on device → top-K pairs.

Mind authority remains Zig Fixed lattice. This is a **body organ worker**:
  1. Load float32 matrix [S, D] from binary (written by gpu_vram_fixed.zig)
  2. Upload to CUDA VRAM as Q=K=V [1,1,S,D]
  3. Run fsot_attn_lib.fsot_consensus_cuda_device (collapse + trit consensus, NO softmax)
  4. Pairwise cosine on consensus outputs (device) → top-K pairs
  5. Write JSON result for Zig to parse

Binary input format (little-endian):
  magic u32 = 0x46534F54 ('FSOT')
  version u32 = 1
  n u32, d u32
  slot_index[n] u32   — original episode indices
  rows[n*d] f32       — row-major fingerprints

Usage:
  python vram_offload.py <in.bin> <out.json> [top_k] [lab_root]
"""
from __future__ import annotations

import ctypes
import json
import os
import struct
import sys
import time
from pathlib import Path

MAGIC = 0x46534F54
COLLAPSE = 0.9174663774653723

LAB_CANDIDATES = [
    os.environ.get("FSOT_GPU_ROOT", ""),
    r"C:\Users\damia\Desktop\gpu exparment for lean coq isabell andf star",
    r"C:\Users\damia\Desktop\FSOT-GPU",
    r"I:\FSOT-GPU",
]


def find_lab(cli: str | None) -> Path | None:
    cands = []
    if cli:
        cands.append(cli)
    cands.extend(LAB_CANDIDATES)
    for c in cands:
        if not c:
            continue
        p = Path(c)
        dll = p / "phase2_native_gpu" / "cuda" / "fsot_attn_lib.dll"
        if dll.is_file():
            return p
    return None


def read_matrix(path: Path) -> tuple[list[int], "object"]:
    import numpy as np

    raw = path.read_bytes()
    if len(raw) < 16:
        raise ValueError("matrix too short")
    magic, ver, n, d = struct.unpack_from("<IIII", raw, 0)
    if magic != MAGIC:
        raise ValueError(f"bad magic {magic:#x}")
    if ver != 1:
        raise ValueError(f"bad version {ver}")
    off = 16
    slots = list(struct.unpack_from("<" + "I" * n, raw, off))
    off += 4 * n
    need = off + n * d * 4
    if len(raw) < need:
        raise ValueError(f"truncated matrix need={need} got={len(raw)}")
    mat = np.frombuffer(raw, dtype=np.float32, count=n * d, offset=off).reshape(n, d).copy()
    return slots, mat


def load_dll(lab: Path):
    dll_path = lab / "phase2_native_gpu" / "cuda" / "fsot_attn_lib.dll"
    lib = ctypes.CDLL(str(dll_path))
    lib.fsot_consensus_cuda.argtypes = [
        ctypes.POINTER(ctypes.c_float),
        ctypes.POINTER(ctypes.c_float),
        ctypes.POINTER(ctypes.c_float),
        ctypes.POINTER(ctypes.c_float),
        ctypes.c_int,
        ctypes.c_int,
        ctypes.c_int,
        ctypes.c_int,
    ]
    lib.fsot_consensus_cuda.restype = ctypes.c_int
    if hasattr(lib, "fsot_consensus_cuda_device"):
        lib.fsot_consensus_cuda_device.argtypes = [
            ctypes.c_void_p,
            ctypes.c_void_p,
            ctypes.c_void_p,
            ctypes.c_void_p,
            ctypes.c_int,
            ctypes.c_int,
            ctypes.c_int,
            ctypes.c_int,
        ]
        lib.fsot_consensus_cuda_device.restype = ctypes.c_int
    if hasattr(lib, "fsot_set_fused"):
        lib.fsot_set_fused.argtypes = [ctypes.c_int]
        lib.fsot_set_fused(-1)  # adaptive mid/long
    return lib


def consensus_vram(lib, mat) -> tuple["object", str]:
    """mat: [S,D] numpy float32 → consensus out [S,D], path tag."""
    import numpy as np
    import torch

    S, D = mat.shape
    # Q=K=V: treat episodes as sequence under one head
    t = torch.from_numpy(mat).to(dtype=torch.float32)
    device = "cuda" if torch.cuda.is_available() else "cpu"
    t = t.to(device)
    # [B=1,H=1,S,D]
    q = t.view(1, 1, S, D).contiguous()
    k = q
    v = q
    out = torch.empty_like(q)

    if device == "cuda" and hasattr(lib, "fsot_consensus_cuda_device"):
        rc = lib.fsot_consensus_cuda_device(
            ctypes.c_void_p(q.data_ptr()),
            ctypes.c_void_p(k.data_ptr()),
            ctypes.c_void_p(v.data_ptr()),
            ctypes.c_void_p(out.data_ptr()),
            1,
            1,
            int(S),
            int(D),
        )
        if rc != 0:
            raise RuntimeError(f"fsot_consensus_cuda_device rc={rc}")
        torch.cuda.synchronize()
        return out.view(S, D).detach().cpu().numpy(), "vram-fsot-consensus-device"

    # Host path still uses CUDA kernels inside DLL (H2D inside)
    qh = q.detach().float().contiguous().cpu().numpy()
    out_np = np.empty_like(qh)
    rc = lib.fsot_consensus_cuda(
        qh.ctypes.data_as(ctypes.POINTER(ctypes.c_float)),
        qh.ctypes.data_as(ctypes.POINTER(ctypes.c_float)),
        qh.ctypes.data_as(ctypes.POINTER(ctypes.c_float)),
        out_np.ctypes.data_as(ctypes.POINTER(ctypes.c_float)),
        1,
        1,
        int(S),
        int(D),
    )
    if rc != 0:
        raise RuntimeError(f"fsot_consensus_cuda rc={rc}")
    return out_np.reshape(S, D), "vram-fsot-consensus-host"


def trit_sim_matrix_gpu(mat) -> "object":
    """Optional: GPU trit similarity matrix for scoring (collapse codes)."""
    import torch

    device = "cuda" if torch.cuda.is_available() else "cpu"
    x = torch.as_tensor(mat, dtype=torch.float32, device=device)
    # codes 0/1/2
    up = x > COLLAPSE
    down = x < -COLLAPSE
    codes = torch.ones_like(x, dtype=torch.int8)
    codes = torch.where(up, torch.tensor(2, device=device, dtype=torch.int8), codes)
    codes = torch.where(down, torch.tensor(0, device=device, dtype=torch.int8), codes)
    # pair trit sim mean over D — O(S^2 D) but S<=384
    S, D = codes.shape
    ca = codes.unsqueeze(1)  # S,1,D
    cb = codes.unsqueeze(0)  # 1,S,D
    super_m = (ca == 1) | (cb == 1)
    same = (ca == cb) & ~super_m
    opp = (ca != cb) & ~super_m
    used = (~super_m).sum(dim=-1).clamp_min(1).to(torch.float32)
    sim = (same.to(torch.float32).sum(dim=-1) - opp.to(torch.float32).sum(dim=-1)) / used
    return sim.detach().cpu()


def top_pairs(out_mat, src_mat, k: int, slots: list[int]) -> list[dict]:
    """Rank pairs using consensus outputs when informative, else source fingerprints.

    Consensus can collapse to near-zero for superposed-only banks; then we still
    return ranked pairs from the **source** matrix (still after VRAM consensus ran).
    """
    import torch
    import numpy as np

    device = "cuda" if torch.cuda.is_available() else "cpu"

    def pair_rank(mat: np.ndarray):
        t = torch.as_tensor(mat, dtype=torch.float32, device=device)
        norms = t.norm(dim=1, keepdim=True).clamp_min(1e-12)
        u = t / norms
        sim = u @ u.T
        trit = trit_sim_matrix_gpu(mat).to(device=device, dtype=torch.float32)
        blend = 0.55 * sim + 0.45 * trit
        S = blend.shape[0]
        mask = torch.triu(torch.ones(S, S, device=device, dtype=torch.bool), diagonal=1)
        blend_m = blend.masked_fill(~mask, -2.0)
        return sim, trit, blend_m, S

    sim, trit, blend_m, S = pair_rank(out_mat)
    # If consensus flattened (all near zero), re-rank on source fingerprints
    if float(blend_m.max().item()) <= 0.0:
        sim, trit, blend_m, S = pair_rank(src_mat)

    flat = blend_m.reshape(-1)
    kk = min(k, max(0, S * (S - 1) // 2))
    if kk <= 0:
        return []
    vals, idx = torch.topk(flat, kk)
    pairs = []
    for v, fi in zip(vals.tolist(), idx.tolist()):
        i = int(fi) // S
        j = int(fi) % S
        if i >= j:
            continue
        pairs.append(
            {
                "i": int(slots[i]),
                "j": int(slots[j]),
                "cos": float(sim[i, j].item()),
                "trit": float(trit[i, j].item()),
                "score": float(v),
            }
        )
    return pairs


def main(argv: list[str]) -> int:
    t0 = time.perf_counter()
    if len(argv) < 3:
        print("usage: vram_offload.py <in.bin> <out.json> [top_k] [lab_root]", file=sys.stderr)
        return 2
    in_path = Path(argv[1])
    out_path = Path(argv[2])
    top_k = int(argv[3]) if len(argv) >= 4 else 8
    lab_cli = argv[4] if len(argv) >= 5 else None

    report: dict = {
        "ok": False,
        "path": "fail",
        "pairs": [],
        "S": 0,
        "D": 0,
        "ms": 0,
        "device": "none",
        "error": "",
    }
    try:
        lab = find_lab(lab_cli)
        if lab is None:
            raise FileNotFoundError("FSOT-GPU lab / fsot_attn_lib.dll not found")
        slots, mat = read_matrix(in_path)
        S, D = mat.shape
        report["S"] = int(S)
        report["D"] = int(D)
        if S < 2:
            report["ok"] = True
            report["path"] = "vram-skip-small"
            report["ms"] = int((time.perf_counter() - t0) * 1000)
            out_path.write_text(json.dumps(report), encoding="utf-8")
            return 0

        lib = load_dll(lab)
        import torch

        report["device"] = "cuda" if torch.cuda.is_available() else "cpu"
        out_mat, path = consensus_vram(lib, mat)
        report["path"] = path
        pairs = top_pairs(out_mat, mat, top_k, slots)
        report["pairs"] = pairs
        report["ok"] = len(pairs) > 0 or S < 2
        report["lab"] = str(lab)
        if torch.cuda.is_available():
            report["gpu_name"] = torch.cuda.get_device_name(0)
        # compact scores for Zig log
        if pairs:
            report["best_score"] = pairs[0].get("score", 0.0)
            report["best_cos"] = pairs[0].get("cos", 0.0)
    except Exception as e:  # noqa: BLE001 — organ surfaces errors to mind
        report["error"] = str(e)
        report["ok"] = False
        report["path"] = "fail"

    report["ms"] = int((time.perf_counter() - t0) * 1000)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(report), encoding="utf-8")
    # also print one line for logs
    print(
        f"VRAM_OFFLOAD ok={report['ok']} path={report['path']} "
        f"S={report['S']} pairs={len(report['pairs'])} ms={report['ms']} "
        f"device={report['device']}"
    )
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
