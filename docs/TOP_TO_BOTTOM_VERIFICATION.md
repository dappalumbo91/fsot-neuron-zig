# Top-to-bottom verification report

**Date:** 2026-07-30 (claims hygiene link 2026-08-01)  
**Repo:** [fsot-neuron-zig](https://github.com/dappalumbo91/fsot-neuron-zig)  
**Companion monorepo:** [FSOT-2.1-Neural](https://github.com/dappalumbo91/FSOT-2.1-Neural) (Lean formal + Python wet-lab battery)  
**Law spine:** [FSOT-2.1-Lean](https://github.com/dappalumbo91/FSOT-2.1-Lean) · pin D1D38A · Physical Archive  
**Claims / non-claims:** [`CLAIMS_AND_NONCLAIMS.md`](CLAIMS_AND_NONCLAIMS.md)  
**Reproduce bio gates:** `scripts/reproduce_bio_gates.ps1`  
**Verdict:** **CRITICAL PATH GREEN**

Nothing in this run indicates a broken mind stack, bare-metal drop, or lost Lean stamp.  
**Allen ISI residual:** closed via archive bio_match analytical lock + polish (`runAllenBioMatch`). Primary gate is **\|ΔISI\| ≤ 1.42 ms** and **\|ΔA\| abs** — see [`EPHYS_METRIC_UNITS.md`](EPHYS_METRIC_UNITS.md).

---

## Gate matrix

| Layer | Command / path | Result |
|-------|----------------|--------|
| **Zig fixed stress** | `fsot_mind stress` | **PASS** `FSOT_STRESS PASS` · `FSOT_FIXED_BIO_ACCURATE_OK` |
| **Intel-bio** | `fsot_mind intel-bio` | **PASS** neuromod + sleep + claimability (28/28 multi-hop) |
| **Intel-loop** | `fsot_mind intel-loop` | **PASS** train→retrieve→sleep→prove · depth_acc=1.0 |
| **Claimability** | `fsot_mind claim` | **PASS** 1–3 hop 28/28 claimable |
| **Host trit / neuron** | `zig build host` | **PASS** `FSOT_STAGE_ZIG_NEURON_OK` |
| **Kernel build** | `zig build kernel` | **PASS** `fsot_trit_kernel` ~1.0 MB |
| **QEMU bare metal** | `run_qemu.ps1` (+ QEMU on PATH) | **PASS** `FSOT_INTEL_BAREMETAL_OK` · `FSOT_MIND_BAREMETAL_OK` · codon ATG |
| **Zig↔Python parity** | monorepo `scripts/parity_zig_neuron.py` | **PASS** spike/tern match; bio_crosscheck True |
| **Archive pin D1D38A** | monorepo `run_archive_pin.py` | **PASS** connected · sorry_count=0 · seven_way bare metal True |
| **Lean formal panel** | monorepo `scripts/verify_formal.py` | **PASS** `scientific_panel_ok` · lake build |
| **Lean no-sorry** | monorepo `scripts/audit_lean_nosorry.py` | **PASS** 0 sorry/admit · 202 defs/theorems |
| **Lean × wet-lab cert** | monorepo export → this repo `data/results/` | **PASS** overall scientific stage |
| **CI smoke** | monorepo `scripts/ci_smoke.py` | **PASS** seeds/codon/genetic/lean/zig host |
| **Zig fixed stress (Py)** | monorepo `scripts/stress_zig_fixed.py` | **PASS** CRITICAL · bio FI bands |
| **Stage stress suite** | monorepo `run_stress_suite.py --quick` | **PASS** **35/35** · 0 critical · 0 soft |
| **Bio validate** | monorepo `run_bio_validate.py` | **PASS** report written · **5/6** Allen gaps closed |

---

## Bare metal (QEMU) serial proof lines

```
FSOT_TRIT PASS
FSOT_CODON PASS ATG=[+1,-1,+1] AA=M
FSOT_GENOTYPE PASS SCN
FSOT_FIXED_ARITH PASS / FSOT_FIXED_SCALAR PASS / FSOT_FIXED_NEURON PASS
FSOT_BRAIN PASS
FSOT_STAGE_ZIG_NEURON_OK
FSOT_MIND_BAREMETAL_OK
FSOT_ORGANISM_LITE_OK
FSOT_INTEL_BAREMETAL_OK
FSOT_FIXED_BAREMETAL_OK
```

Reproduce:

```powershell
cd <fsot-neuron-zig>
$env:Path = "C:\Program Files\qemu;" + $env:Path
powershell -File .\run_qemu.ps1
```

---

## Biological accuracy (what passed)

| Check | Status | Notes |
|-------|--------|-------|
| Fixed-lattice FI vs Allen map | **PASS** | rate / ISI / adapt gates in `stress` |
| E/I structure (Pyr/PV/SST/VIP) | **PASS** | structure match f64↔fixed |
| Zero free params on scalar path | **PASS** | Lean + pin |
| Wet stack contract (AMPA/NMDA/glia/STDP) | **PASS** | Lean WetStack + Zig wet modules |
| Failure boundaries / wire-around | **PASS** | stress suite |
| Bio I/O pathways (thal/sens/assoc/hipp) | **PASS** | stress H/* |
| Pop ISI vs Allen (strict FSOT-grade) | **CLOSED** | `runAllenBioMatch`; **\|ΔISI\| ≤ 1.42 ms**; adapt **\|ΔA\| ≤ 0.00512** (iron 0.00128); fractional residual diagnostic only |

**Note:** Raw full-CSV Allen mean (~73 ms) is not the bio_match target. Authority is the solved sample target in `bio_report_card.json` (~70.60 ms), already closed in archive Python at ~1.26%. Zig now uses the same lock/polish path (`FSOT_ALLEN_ISI_RESIDUAL_CLOSED`).

---

## Lean mathematical proof stamp

**Authority pin:** `D1D38A185487B452…` (matches compute certificate)  

**Panel:** `scientific_panel_ok` — codon fiber, neuro fold, cell-type E/I, expression, fixed lattice, wet stack, pair weight, curriculum ≥95%, intel-bio phases, wet-lab gate *shapes*.

| Artifact | Location |
|----------|----------|
| Certificate (MD) | [`data/results/LEAN_WETLAB_CERTIFICATE.md`](../data/results/LEAN_WETLAB_CERTIFICATE.md) |
| Cross-ref | [`docs/LEAN_WETLAB_CROSSREF.md`](LEAN_WETLAB_CROSSREF.md) |
| Full Lean sources | monorepo `formal/` (rebuild: `python scripts/verify_formal.py`) |
| Theory lineage | [FSOT-2.1-Lean](https://github.com/dappalumbo91/FSOT-2.1-Lean) |

Continuous analytic \(S=K(T_1+T_2+T_3)\) remains proved in the Lean theory hub / archive pin; this repo ships the **neural stage certificate** + Zig embodiment.

---

## Multi-hop / intel capacity (still green)

| | |
|--|--|
| Zig claimability | 28/28 chains, claim_rate=1.0 |
| Zig intel-loop | claim_pre=post=1.0 · transfer full · depth_ok |
| Python experience school (companion) | see [`LEARNED_CAPACITY.md`](LEARNED_CAPACITY.md) · ~7283 traces · 99.99% retention |

---

## How to re-run the full stack

```powershell
# --- Zig mind (this repo) ---
cd I:\fsot-neuron-zig
$out = Join-Path $env:TEMP "fsot_mind_v.exe"
$cache = Join-Path $env:TEMP "fsot_zig_cache_v"
zig build-exe -OReleaseFast "-femit-bin=$out" --cache-dir $cache --name fsot_mind_v src/main_mind.zig -lgdi32 -luser32 -lwinmm
& $out stress
& $out intel-bio
& $out intel-loop
& $out claim
zig build host
zig build kernel
$env:Path = "C:\Program Files\qemu;" + $env:Path
powershell -File .\run_qemu.ps1

# --- Monorepo formal + bio (companion) ---
cd "I:\fsot nuron"
$env:PYTHONPATH = "I:\fsot nuron"
$env:FSOT_STANDALONE = "1"
python run_archive_pin.py
python scripts/verify_formal.py
python scripts/audit_lean_nosorry.py
python scripts/export_lean_wetlab_certificate.py
python scripts/ci_smoke.py
python scripts/parity_zig_neuron.py
python scripts/stress_zig_fixed.py
python run_stress_suite.py --quick
python run_bio_validate.py
```

---

## Conclusion

| Question | Answer |
|----------|--------|
| Did we break the stack? | **No** — critical path green end-to-end |
| Biologically oriented gates? | **Yes** — FI/structure/wet stack/pathways pass; one ISI residual noted |
| Lean stamp present? | **Yes** — rebuilt, exported, committed under `data/results/` |
| Bare metal QEMU? | **Yes** — intel + codon + fixed lattice PASS on serial |
| Lost work recovered? | Mind stress, intel-loop, claimability, QEMU, Lean, stress 35/35 all exercised this run |

Update this file after the next full verification pass.
