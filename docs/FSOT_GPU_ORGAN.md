# GPU organ — FSOT-GPU as body compute

**Mind authority:** Fixed genetic lattice in `fsot-neuron-zig`  
**GPU reference (solved):** [FSOT-GPU](https://github.com/dappalumbo91/FSOT-GPU)  
**Local lab:** `Desktop/gpu exparment for lean coq isabell andf star`  
**Env override:** `FSOT_GPU_ROOT=<path to FSOT-GPU clone>`

---

## Doctrine (same as FSOT-GPU)

| Layer | Role |
|-------|------|
| FSOT seeds + Fixed lattice | **Mind** — never replaced by PyTorch |
| Lean · Coq · Isabelle · F\* | **Contracts** — packing, memory, boot scalar |
| CUDA / trinary pack / consensus | **Body organ** — parallel compute |
| Disk LTM + RAM STM | Memory hierarchy |
| Python skills | Procedural organ (interpreter), not second brain |

Industry tools (CUDA toolkit, torch) are **optional backends**.  
They are not the theory and not the product. See FSOT-GPU `docs/OWNED_STACK.md`.

```
FSOT Fixed mind (this repo)
        │
        ├── STM (RAM) · LTM (disk)
        ├── CPU serial / small-batch thought
        └── GPU organ ──bridge──► FSOT-GPU
                trinary pack · collapse threshold
                consensus attention (no softmax)
                native .cu kernels when built
```

---

## What shipped in the mind

| Piece | Mode / module |
|-------|----------------|
| Device probe (nvidia-smi) | `gpu_organ_fixed.probe` |
| Owned trinary pack + collapse parity | same constants as FSOT-GPU `parity/zig_parity` |
| Locate FSOT-GPU lab + kernel binaries | `FSOT_GPU_ROOT` or Desktop lab path |
| Native `trinary_pack_test.exe` smoke | when binary present |
| Sleep consolidate hook | think loop → `consolidateBatch` |
| Capacity report GPU detail | `fsot_mind capacity` |

```text
fsot_mind gpu-organ
fsot_mind capacity
```

---

## Collapse threshold (seed-owned)

```
COLLAPSE_THRESHOLD = C_eff · P_var ≈ 0.917466…
```

Matches FSOT-GPU / archive / trinary kernel. Not a free hyperparameter.

---

## Batch sleep replay (shipped)

```text
fsot_mind gpu-batch
fsot_mind gpu-vram
```

| Step | Where |
|------|--------|
| Pairwise fingerprint **cosine** (STM window) | `gpu_batch_fixed.findTopPairs` (CPU fallback) |
| **Trit consensus** affinity (collapse, no softmax) | `gpu_batch_fixed.tritSimFp` |
| **Full VRAM offload** | `gpu_vram_fixed` → `skills/python/vram_offload.py` |
| CUDA Q=K=V consensus | `fsot_attn_lib.dll` `fsot_consensus_cuda_device` |
| Device top-K pairs | cosine + trit blend on consensus outputs |
| Top-K **co-activation + re-encode** | `sleepReplayBatch` during think NREM |
| Native pack smoke | `consolidateBatch` when lab binaries present |

### VRAM pipeline

```text
STM episodes (Fixed fp)
  → data/ltm/vram_in.bin   (float32 matrix + slot map)
  → vram_offload.py
       upload [1,1,S,D] Q=K=V to CUDA
       fsot_consensus_cuda_device  (collapse, trit, no softmax)
       pairwise top-K on device
  → data/ltm/vram_out.json
  → Zig sleep replay of returned pairs
```

Think loop: `sleepWithBatch` prefers VRAM when `attn_dll` present, else CPU Fixed.  
`THINK_ORGANS … batch_replay=N mean_cos=…`  
Path tags: `vram-fsot-consensus` | `cpu-fixed` | `cpu-fixed+fsot-gpu`

## What remains on the FSOT-GPU side

Heavy competitive kernels stay in FSOT-GPU:

1. Sparse vs softmax microbenches (`competitive/beat_cuda_suite.py`)  
2. Formal specs under `phase1_formal_gpu/`  
3. Industry SafeTensors all-layer host  
4. FlashAttention-track long-context benches  

Mind optional later: vision batch features under Fixed inject ABI.

---

## Related

- [SILICON_BODY_ARCHITECTURE.md](SILICON_BODY_ARCHITECTURE.md)  
- [MINIMUM_STACK.md](MINIMUM_STACK.md)  
- FSOT-GPU README · `docs/ARCHITECTURE.md` · `docs/OWNED_STACK.md`  
