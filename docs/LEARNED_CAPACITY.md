# Learned capacity snapshot — fsot-neuron-zig

**Date:** 2026-07-30  
**Repo:** [fsot-neuron-zig](https://github.com/dappalumbo91/fsot-neuron-zig)  
**Doctrine:** train → sleep → prove · claimability · intel-bio / intel-loop  
**Not claimed:** GSM8K test leaderboard as a product score; LLM Q→A stuffing  
**Full stack verify:** [`TOP_TO_BOTTOM_VERIFICATION.md`](TOP_TO_BOTTOM_VERIFICATION.md) · Lean cert [`../data/results/LEAN_WETLAB_CERTIFICATE.md`](../data/results/LEAN_WETLAB_CERTIFICATE.md)  
**Real-brain teach bridge:** [`BRAIN_LEARN_BRIDGE.md`](BRAIN_LEARN_BRIDGE.md) · `fsot_mind brain-learn`

Honest inventory of the **Zig neurological mind**. School knowledge now **encodes into OrganismF** via `brain-learn` (not Python-only side banks).

---

## Zig neurological brain (this repo)

| | |
|--|--|
| **Authority** | Fixed-point lattice (`src/fixed.zig`, SCALE=1e12) |
| **Mind host** | `zig build` / `BOOT_MIND.cmd` → `fsot_mind` modes |
| **Core** | `brain_fixed`, `neuron_fixed`, `genetic_fixed`, `organism_fixed`, `memory_fixed`, `learning_fixed` |
| **Wet stack** | `channel_stoch_fixed` · `molecular_fixed` · `glia_fixed` · `stdp_fixed` |
| **Intel** | `neuromod_fixed` · `sleep_replay_fixed` · `claimability_fixed` · `intel_loop_fixed` · `intel_frontier_fixed` |
| **Curriculum** | `grade_ladder_fixed` PK→G8 · `understand_depth_fixed` · `teach_fixed` · `transfer_fixed` |
| **I/O** | host senses · speech organ · machine-lang · MNIST gate pack under `data/multimodal/` |

```powershell
# Windows live mind (if AV locks zig-out)
$out = Join-Path $env:TEMP "fsot_mind_live.exe"
$cache = Join-Path $env:TEMP "fsot_zig_cache_live"
zig build-exe -OReleaseFast "-femit-bin=$out" --cache-dir $cache --name fsot_mind_live src/main_mind.zig -lgdi32 -luser32 -lwinmm
& $out intel-bio
& $out intel-loop
& $out claim
& $out mind
```

Or double-click `BOOT_MIND.cmd`.

**Binaries** (`zig-out/`, temp exes) are **not** committed — rebuild locally.

---

## Companion multi-hop experience capacity (Python monorepo)

The **method memory** from the experience school lives with the Python organism in the related monorepo, driven by the same train→sleep→prove doctrine as Zig intel-loop / claimability.

| | |
|--|--|
| **Monorepo** | [FSOT-2.1-Neural](https://github.com/dappalumbo91/FSOT-2.1-Neural) |
| **Organism** | `fsot_nuron/math_multihop_organism.py` |
| **Teacher** | `scripts/run_multihop_experience_learn.py` |
| **Snapshot report (also copied here)** | [`data/results/MATH_EXPERIENCE_LEARN.json`](../data/results/MATH_EXPERIENCE_LEARN.json) |

### Full GSM8K **train** experience run (2026-07-30)

| Metric | Value |
|--------|------:|
| Worked lessons loaded | 7378 |
| Successfully taught (hop traces) | **7284** (~98.7%) |
| Traces retained | **7283** |
| Taught-wording retention | **99.99%** (7283/7284) |
| Novel-number transfer | **100%** (100/100 prove) |
| Mean trace strength | ~2.51 |

Reproduce (from monorepo, with GSM8K train.jsonl available):

```powershell
cd <FSOT-2.1-Neural>
$env:PYTHONPATH = (Get-Location).Path
$env:FSOT_STANDALONE = "1"
python scripts/run_multihop_experience_learn.py --train-limit 8000 --epochs 8
```

### What “learned” means

1. Teacher shows worked lessons (curriculum information).  
2. Student retains **methods** (hop traces / claim chains), not exam answer keys.  
3. Practice + sleep densify; prove is transfer / retention.  
4. Zig stack: neuromod + sleep + multi-hop claimability + intel-loop.  
5. Python stack: episodic hop traces + WM atomics (companion capacity above).

---

## Zig modes that exercise learned / intel stack

| Mode | Role |
|------|------|
| `neuromod` | DA/ACh/NE/5-HT fixed ODEs |
| `sleep` / `consolidate` | Offline replay densify |
| `claim` / `claimability` | Multi-hop grounded claims |
| `intel-bio` | Full neuromod + sleep + claim |
| `intel-loop` | Closed train→retrieve→sleep→prove |
| `frontier` | Multi-day curiosity + sleep |
| `ladder` / `depth` | PK→G8 / paraphrase understand gates |
| `teach` / `transfer` / `short-horizon` | Memory learning |

---

## Explicitly not claimed

- Official GSM8K **test** overall accuracy as the product metric  
- That Zig and Python multi-hop banks are fused in one process  
- Medical / clinical equivalence  

Update this file when a new Zig mind milestone or full experience run lands.
