# Claims and non-claims — neural Zig mind

**Repo:** [fsot-neuron-zig](https://github.com/dappalumbo91/fsot-neuron-zig)  
**Date:** 2026-08-01  
**Purpose:** Scientific claim hygiene. Only what is verified in artifacts.

**Law spine (shared with cosmology folds):** pin **D1D38A** · \(S=K(T_1+T_2+T_3)\)  
→ [FSOT-2.1-Lean](https://github.com/dappalumbo91/FSOT-2.1-Lean) · `I:\FSOT-Physical-Archive`  
→ map: [`ARCHIVE_PIN_AND_MIND_FOLD.md`](ARCHIVE_PIN_AND_MIND_FOLD.md)

---

## We claim (verified)

### Law / architecture

| Claim | How verified |
|-------|----------------|
| One FSOT scalar law under pin D1D38A | Archive + Lean verification bundle; live pin match in monorepo/archive |
| Cosmology and neural mind are **domain folds** of that law (not two free-parameter theories) | Archive fold table + usage doctrine; Zig solidification docs |
| Fixed lattice SCALE=1e12 is mind dynamics authority in this repo | `src/fixed.zig`; `fsot_mind fixed` / stress suite |
| Zero free LSQ levers on the **law path** | Archive parameter honesty + pin (not re-fitted per Allen rate) |

### Domain engine (this repo) — public ephys / structure

| Claim | How verified |
|-------|----------------|
| **Every** FI cell: **\|ΔISI\| ≤ 1.42 ms**, **\|ΔA\| ≤ 0.00512**, **\|Δr\| ≤ 0.40 Hz** | `fsot_mind fixed` → `FSOT_EVERY_CELL_BIO_MATCH_OK` · mean alone not enough |
| Pop mean also closed (same native units) + iron when achievable | `FSOT_ALLEN_ISI_RESIDUAL_CLOSED` · `FSOT_EPHYS_NATIVE_UNITS_OK` |
| **Every** class replicate Pyr/PV/SST/VIP: **\|Δr\| Hz** + PV ≫ Pyr | `fsot_mind scalpel` → `FSOT_EVERY_CELL_CLASS_RATE_OK` |
| **Allen CSV variance:** stratified specimen sample mean/sd/quantiles + KS | `fsot_mind allen-dist` / `fixed` → `FSOT_ALLEN_CSV_VARIANCE_OK` · `FSOT_KS_ISI_ADAPT_OK` |
| **Cre-class variance:** Pyr/PV/SST/VIP each match Allen mouse Cre dist + KS + PV≫Pyr | `fsot_mind allen-class-dist` / `fixed` → `FSOT_CRE_CLASS_VARIANCE_OK` |
| **Full ISI distribution KS (product):** genetic class ORF + mutateOrf seed + soft specimen polish → two-sample KS vs Allen sample + mean/SD/quantiles vs full CSV | `fsot_mind isi-ks` → `FSOT_ALLEN_ISI_KS_PRODUCT PASS` · `FSOT_KS_VS_ALLEN_CSV_OK` · `FSOT_GENETIC_ISI_KS_OK` |
| Genetic structure (codon ORFs, E/I, pair W) | suite + Neural Lean structure panel |
| Wet process cascade runs on think encode (STDP/glia/mol/consol/prune) | think logs: `THINK_WET`, non-zero stdp/releases; mut≠0 plasticity |
| STM/LTM disk spill + warm | `ltm_disk_fixed`; hour logs warm/spill counts |
| Bio metrics are process metrics, not LLM benches | `metric_kind=bio_episodic_not_llm`; doctrine docs |
| Answer-dependent composition (hop N from answer N−1) with ablation dependence | `fsot_mind compose` → `FSOT_COMPOSE_INTEL PASS` · claim ≥90% · ablate break ≥80% |
| Schema edges induced from experience pairs + static baseline | same · `FSOT_SCHEMA_DISCOVERY_OK` |
| Compose module inside intel-loop regression | `fsot_mind intel-loop` · `compose_mod=true` |

### Process organism (measured on host)

| Claim | How verified |
|-------|----------------|
| Encode → retrace → discover → sleep → LTM path runs | `think` / `think-hour` DONE lines |
| Episodic retrace can hold at high fidelity on grown cues | think accuracy JSONL / HB `episodic_retr` |
| Plasticity changes W fingerprint | `THINK_GENETIC.log` MUTATION lines |

Reproduce domain gates:

```powershell
.\scripts\reproduce_bio_gates.ps1
# or:
.\zig-out\bin\fsot_mind.exe fixed
.\zig-out\bin\fsot_mind.exe scalpel
.\zig-out\bin\fsot_mind.exe isi-ks   # full ISI distribution KS product
```

---

## We do **not** claim

| Non-claim | Why |
|-----------|-----|
| Peer-reviewed acceptance of FSOT as standard cosmology | Archive GREEN ≠ journal consensus; external replication welcome |
| Molecular identity with wet tissue / Cortical Labs | Silicon process models, not living MEA |
| “Solved” human-level child cognition or AGI | Think-hour is process loop metrics |
| Curriculum ≥95% = human PK–G8 / PISA mastery | Project **gate pass** on **project banks** only |
| GSM8K / MMLU / chat SOTA as primary | Explicitly rejected as primary north star (`BIO_LEARNING_DOCTRINE.md`) |
| MD all-atom is cognition | Lab only (`WHY_NOT_ALL_ATOM_MD.md`) |
| Think composition quality = scientific novelty | Internal idea hygiene; residual paper-token scrap still possible |
| Independent third-party audit of every hour log | Host runs are reproducible *if* machine matches; not yet community-run |

---

## How to read a number

1. **Law pin** — D1D38A / Lean / archive.  
2. **Domain fold** — neuroscience embodiment in Zig.  
3. **Metric** — Allen, scalpel, think bio JSONL, structure.  
4. **Protocol** — command + file path.  

If a sentence has no protocol, it is not a shipping claim.

---

## Related

- [`ARCHIVE_PIN_AND_MIND_FOLD.md`](ARCHIVE_PIN_AND_MIND_FOLD.md)  
- [`ARCHIVE_ZIG_BIO_CROSSREF.md`](ARCHIVE_ZIG_BIO_CROSSREF.md)  
- [`BIO_LEARNING_DOCTRINE.md`](BIO_LEARNING_DOCTRINE.md)  
- [`TOP_TO_BOTTOM_VERIFICATION.md`](TOP_TO_BOTTOM_VERIFICATION.md)  
- [`FSOT_MATH_SYSTEM_SOLIDIFIED.md`](FSOT_MATH_SYSTEM_SOLIDIFIED.md)  
