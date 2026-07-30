"""Skill: gpu_topk — batch cosine top-1 among row vectors (optional CUDA).

Input format (single arg string):
  N D | v00 v01 ... v0{D-1} | v10 ... | ...

Example:
  3 2 | 1 0 | 0 1 | 1 0.1

Returns: best_i best_j cos  (indices of closest pair)
Uses torch CUDA if available, else CPU numpy-free pure Python.
Not mind authority — optional organ accelerator for large matrices.
"""

from __future__ import annotations


def _parse(arg: str) -> list[list[float]]:
    # split by |
    parts = [p.strip() for p in arg.split("|")]
    if len(parts) < 2:
        raise ValueError("need 'N D | row0 | row1 | ...'")
    header = parts[0].split()
    if len(header) < 2:
        raise ValueError("header needs N D")
    n, d = int(header[0]), int(header[1])
    rows: list[list[float]] = []
    for p in parts[1 : 1 + n]:
        vals = [float(x) for x in p.split()]
        if len(vals) != d:
            raise ValueError(f"row len {len(vals)} != D={d}")
        rows.append(vals)
    if len(rows) != n:
        raise ValueError(f"got {len(rows)} rows, expected N={n}")
    return rows


def _cosine(a: list[float], b: list[float]) -> float:
    dot = sum(x * y for x, y in zip(a, b))
    na = sum(x * x for x in a) ** 0.5
    nb = sum(x * x for x in b) ** 0.5
    if na < 1e-12 or nb < 1e-12:
        return 0.0
    return dot / (na * nb)


def run(*args: str) -> str:
    raw = " ".join(args) if args else ""
    rows = _parse(raw)
    n = len(rows)
    if n < 2:
        return "0 0 0"
    # try torch CUDA path
    try:
        import torch

        t = torch.tensor(rows, dtype=torch.float32)
        device = "cuda" if torch.cuda.is_available() else "cpu"
        t = t.to(device)
        # normalize rows
        norms = t.norm(dim=1, keepdim=True).clamp_min(1e-12)
        u = t / norms
        sim = u @ u.T
        sim.fill_diagonal_(-2.0)
        flat = sim.argmax().item()
        bi, bj = divmod(int(flat), n)
        # ensure i < j for stable report
        if bi > bj:
            bi, bj = bj, bi
        cos = float(sim[bi, bj].item())
        return f"{bi} {bj} {cos:.6f} device={device}"
    except Exception:
        pass
    # pure python fallback
    best_i, best_j, best = 0, 1, -2.0
    for i in range(n):
        for j in range(i + 1, n):
            c = _cosine(rows[i], rows[j])
            if c > best:
                best, best_i, best_j = c, i, j
    return f"{best_i} {best_j} {best:.6f} device=cpu"
