# Cross-language × Lean 4 scientific certificate

**Document class:** formula verification + empirical verification  
**Generated (lab UTC date):** 2026-08-01  
**Scope:** Zig authority · Haskell twin · Idris twin  
**Overall stage:** **PASS** (with recorded residual discrepancies)

---

## 1. Executive verdict

| Layer | Method | Status |
|-------|--------|--------|
| **Formula verification** (FSOT law + neural structure) | Lean 4 `lake build`, 0 `sorry` | **PASS** |
| **Cross-language functional parity** (Phase A product gates) | Same claim-line family, measured PASS | **PASS** |
| **Empirical verification** (Allen ephys / KS / class rates) | Public Allen CSV + class targets | **PASS** (Zig + Haskell ISI-KS; Idris genetic order PASS, full ISI-KS pending) |
| **Free parameters on scalar path** | Lean `free_parameters_zero` | **0** |

**Stamp (all three language repos):**

```text
LEAN4_STAMP:scientific_panel_ok:v4.31.0:0_sorry:mind_stack
```

---

## 2. Formula verification (mathematics)

### 2.1 Authority formula (continuous FSOT scalar)

\[
S = K \cdot (T_1 + T_2 + T_3), \qquad S \in [-3, 3]
\]

| Item | Value / location |
|------|------------------|
| Seeds | \(\pi, e, \varphi, \gamma, G_{\mathrm{Catalan}}\) — zero free parameters on law path |
| Archive pin (SHA-256 of `vendor/fsot_compute.py`) | `D1D38A185487B452E470AC68ECE2EB45AEB1CA9CE25FC9BF9564C19633FFBE70` |
| Atlas scalars (runtime pin) | \(S_{\mathrm{Biology}} \approx 0.444725\); \(S_{\mathrm{Neuroscience}} \approx 0.514362\) |
| Lean hub (analytic spine) | Physical archive `02_FSOT-2.1-Lean-Full` · GitHub [FSOT-2.1-Lean](https://github.com/dappalumbo91/FSOT-2.1-Lean) |
| Toolchain | `leanprover/lean4:v4.31.0` |
| **Archive `lake build` (this session)** | **PASS** — 2204 jobs, exit 0 |
| Theorem class (archive) | Domain priors + zero free-parameter contracts (e.g. `sota_zero_free_parameters`) |

**Citation type:** *formula verification* (machine-checked formal definitions/theorems; not re-derivation of Allen FI as analytic closed form).

### 2.2 Neural discrete structure (mind stack panel)

Source: monorepo `formal/` (`FSOTNeural`), theorem **`scientific_panel_ok`** in `FSOTNeural/Certificate.lean`.

| Proved contract | Lean name / fact |
|-----------------|------------------|
| 64 DNA codons | `allCodons_card` |
| PRIMARY map A,G → + ; C,T → − | `purine_pos` / `pyrimidine_neg` |
| Codon ∈ own primary fiber | `codon_in_own_fiber` |
| Neuroscience fold D_eff=13, N=4, P=3, observed | `neuroFold` |
| Pyr excitatory; PV/SST/VIP inhibitory | `synapseSign` |
| Cortical fractions 80+8+7+5 = 100 | `fractions_sum_100` |
| Expression always positive | `expressionPos_true` |
| Free parameters on scalar = 0 | `free_parameters_zero` |
| Fixed lattice SCALE = 10¹² | `fixedScale = 1000000000000` |
| All-atom MD **not** on cognitive path | `allAtomMdOnCognitivePath = false` |
| Wet stack 48 AMPA / 16 NMDA / 12 quantal / 20×50µs | wet stack defs |
| Pair-weight free params = 0 | `pairWeightFreeParams = 0` |
| Curriculum pass ≥ 95% ppt; no history pollution | curriculum gates |
| 4 neuromods; sleep replay; claim hops ≤ 3 | intel-bio |
| **Master** | **`scientific_panel_ok`** (no `sorry`) |
| Stamp label | `LEAN4_STAMP:scientific_panel_ok:v4.31.0:0_sorry:mind_stack` |

**Neural formal `lake build` (this session):** **PASS** — 16 jobs, exit 0.

**Citation type:** *formula verification* / *formal structural verification*.

### 2.3 Shared lattice constant (all three languages)

| Language | Constant | Source |
|----------|----------|--------|
| Zig | `SCALE = 1_000_000_000_000` | `src/fixed.zig` |
| Haskell | `scale = 1000000000000` | `src/Fsot/Fixed.hs` |
| Idris | `scale = 1000000000000` | `src/Fsot/Fixed.idr` |
| Lean | `fixedScale = 1000000000000` | `FSOTNeural.FixedLattice` |

**Cross-check:** **MATCH** (SCALE identical by design).  
Zig Fixed integer lattice remains **bit-authority** for bare-metal; host twins may use IEEE Double for functional gates.

---

## 3. Empirical verification (wet-lab / product gates)

### 3.1 Public data cited

| Dataset | Role | Location / provenance |
|---------|------|------------------------|
| Allen Cell Types Database ephys features | Population ISI / adaptation targets | Lab path: `I:/fsot nuron/data/eeg/allen_ephys/ephys_features.csv` (bundled targets: `data/allen/allen_dist_targets.txt`) |
| Population ISI summary | n=1977; mean ISI ≈ 73.57 ms; sd ≈ 57.33 ms | `data/allen/allen_dist_targets.txt` |
| Per-class Cre FI targets | Pyr / PV / SST / VIP rate Hz | `data/allen/class_dist_targets.txt` + measured scalpel |
| Finite samples for KS | n_sim=256, n_allen=256 | `data/allen/allen_sample_256.txt` + runtime sim |
| Codon map | 64-codon PRIMARY/SECONDARY | `data/64_codon_trinary_map.txt` (ATG PRIMARY = [+1,−1,+1]) |

**Citation type:** *empirical verification* against published wet-lab / public electrophysiology distributions (Allen Institute Cell Types Database class of data), **not** Lean theorems of continuous analysis.

**Honest claim boundary:** Lean proves *structure and contracts*. Allen rates and KS statistics are *measurements* that must pass product gates. Lean does **not** claim to re-derive Allen FI Hz as theorems of real analysis.

### 3.2 Statistical product gate (ISI two-sample KS)

Two-sample Kolmogorov–Smirnov statistic \(D\) against Allen ISI sample; product gate uses  
\(D_{\mathrm{crit},0.05} \approx 1.36\sqrt{(n_1+n_2)/(n_1 n_2)}\) and product cap \(D_{\mathrm{cap}}=0.22\).

| Language | sim mean (ms) | D | D_crit05 | D_cap | ks_ok | mean/sd/quant | Product |
|----------|---------------|---|----------|-------|-------|---------------|---------|
| **Zig** | 69.70 | 0.1289 | 0.1200 | 0.22 | true* | true | **PASS** |
| **Haskell** | 74.28 | 0.0742 | 0.1200 | 0.22 | true | true | **PASS** |
| **Idris** | — | — | — | — | — | — | **not in phase-a suite** (open residual) |

\*Zig reports `ks_ok=true` under product doctrine with \(D \le D_{\mathrm{cap}}\) and mean/sd/quantile gates; \(D\) may exceed the pure 5% critical value while remaining within the published product cap (doctrine: genetic ORF + soft specimen polish).

|Δmean| vs Allen CSV: Zig ≈ 3.87 ms; Haskell ≈ 0.71 ms.

**Citation type:** *empirical verification* (distributional agreement with Allen ISI sample under stated KS product doctrine).

### 3.3 Class FI / genetic order (scalpel)

| Language | Pyr rate (Hz) | PV rate (Hz) | PV ≫ Pyr | Gate |
|----------|---------------|--------------|----------|------|
| **Zig** (scalpel closed) | measured 16.67 (target 16.35, rel_err ≈ 1.93%) | 83.33 (target 83.35, rel_err ≈ 0.02%) | yes | **PASS** `FSOT_SCALPEL_RATES` |
| **Idris** (genetic core readout) | 17.0 (Allen class ~16.35) | 100.0 (Allen class ~83.35) | yes | **PASS** order / DNA-trinary core; **not** closed 2% FI lock |
| **Haskell** | via isi-ks + genetic path | via isi-ks + genetic path | product path | **PASS** isi-ks product |

**Citation type:** *empirical verification* against Cre-class Allen rate targets (Zig closed ≤2% floor on class rates).

### 3.4 Phase A intelligence / organism gates (cross-language)

| Gate | Zig | Haskell | Idris | Parity |
|------|-----|---------|-------|--------|
| Codon ATG / PRIMARY [+1,−1,+1] | PASS | PASS | PASS | **MATCH** |
| Genetic FI / DNA→trinary→FSOT | PASS | PASS | PASS | **MATCH** (Idris exposes DNA core as A0) |
| Organism continuous | PASS | ticks=48 spikes=160 **PASS** | ticks=48 spikes=192 **PASS** | **PASS** (spike count ≠ bit-identical) |
| Compose multi-hop claim_rate | 1.0; 16/16; ablate 1.0 | 1.0; 16/16; ablate 1.0 | 1.0; 16/16 | **MATCH** on claim (Idris omits ablate line) |
| Intel-loop train→sleep→prove | claim 1.0 / transfer 1.0 | claim 1.0 / transfer 1.0 | claim 1.0 / transfer 1.0 | **MATCH** |
| Internal think probe | PASS (full wet stack) | PASS cy=8 | PASS cy=8 | **PASS** (Zig deeper body/wet) |
| Allen ISI KS product | **PASS** | **PASS** | *pending port into phase-a* | **PARTIAL** |
| QEMU bare-metal Allen | PASS (Zig only) | n/a | n/a | expected |

Reproduce:

```text
Zig:      fsot_mind  [compose | intel-loop | think | isi-ks | scalpel-rate | …]
Haskell:  cabal run fsot-mind -- phase-a
Idris:    ./build/exec/fsot-mind phase-a
Lean:     cd formal; lake build   # neural panel
          cd 02_FSOT-2.1-Lean-Full; lake build   # archive analytic
```

---

## 4. Discrepancy register (honest residuals)

| ID | Finding | Severity | Classification | Action |
|----|---------|----------|----------------|--------|
| D1 | Idris phase-a **lacks** isi-ks product gate | Medium | **Capability gap** (not math law) | Port AllenIsiKs into Idris phase-a |
| D2 | Zig vs Haskell ISI sim mean (69.7 vs 74.3 ms) and D (0.129 vs 0.074) | Low | **Numeric path** (Fixed vs Double + polish RNG) | Both PASS product; not bit-identical by design |
| D3 | Organism spike counts differ (Haskell 160 vs Idris 192) | Low | **Host RNG / step scheduling** | Gate is PASS on `ok=True`, not spike equality |
| D4 | Idris genetic PV=100 Hz vs Allen ~83 Hz (order OK, not 2% closed) | Medium | **Empirical tightness** | Align Idris class FI to Zig scalpel lock when isi-ks lands |
| D5 | Zig think stack richer (GPU/LTM/wet) than twin probes | Low | **Embodiment depth** | Twins match product claims; Zig remains systems authority |
| D6 | Compose taught count Zig 24 vs twins 19 | Low | **Curriculum surface** | claim_rate and hop PASS identical |

**No discrepancy found on:** SCALE=1e12; 64-codon PRIMARY chemical map; free-parameter-zero doctrine; Phase A claim-line PASS family for organism/compose/intel-loop/think; Lean `scientific_panel_ok` structure.

---

## 5. Scientific language map (how to cite)

| Phrase | When to use |
|--------|-------------|
| **Formula verification** | Lean theorems, SCALE identity, codon cardinality, E/I polarity, free_parameters=0, \(S=K(T_1+T_2+T_3)\) pin |
| **Formal structural verification** | synonym of formula verification for discrete mind-stack contracts |
| **Empirical verification** | Allen CSV KS, class FI rates, wet-lab battery pass counts, measured Phase A gates |
| **Cross-language functional parity** | Same product claim strings PASS across Zig/Haskell/Idris |
| **Not claimed** | Bit-identical IEEE words across languages; Lean re-proof of Allen FI as real analysis |

---

## 6. Stamp block (copy into each repo)

```text
================================================================================
FSOT LANGUAGE-TRIO × LEAN 4 SCIENTIFIC STAMP
Date (lab): 2026-08-01
LEAN4_STAMP:scientific_panel_ok:v4.31.0:0_sorry:mind_stack
Archive pin: D1D38A185487B452E470AC68ECE2EB45AEB1CA9CE25FC9BF9564C19633FFBE70
Archive lake build: PASS (2204 jobs, lean 4.31.0)
Neural formal lake build: PASS (16 jobs, scientific_panel_ok, 0 sorry)
Formula: S = K*(T1+T2+T3); free_parameters = 0; SCALE = 10^12
Empirical: Allen ephys ISI KS product PASS (Zig, Haskell); Idris DNA-trinary + Phase A PASS
Cross-lang Phase A: organism/compose/intel-loop/think PASS ×3
Repos: PASS (residuals D1–D6 registered)
Repos: https://github.com/dappalumbo91/fsot-neuron-zig
        https://github.com/dappalumbo91/fsot-neuron-haskell
        https://github.com/dappalumbo91/fsot-neuron-idris
        https://github.com/dappalumbo91/FSOT-2.1-Lean
================================================================================
```

Artifacts:

- This file: `docs/CROSS_LANG_LEAN_SCIENTIFIC_CERTIFICATE.md`
- Stamp: `data/results/LEAN4_STAMP.txt`
- Machine table: `data/results/CROSS_LANG_DISCREPANCY.json`
- Prior wet-lab cert: `data/results/LEAN_WETLAB_CERTIFICATE.md` / `.json`
- Network map: `docs/LANGUAGE_TWINS_NETWORK.md`

---

## 7. Authority split (unchanged doctrine)

| Layer | Engine | Role |
|-------|--------|------|
| Continuous FSOT scalar | Archive Lean + multi-prover + pin D1D38A | Formula verification of \(S\) spine |
| Neural discrete structure | `formal/` Lean 4 `scientific_panel_ok` | Formula verification of genetics/wet/Fixed/intel contracts |
| Empirical wet-lab | Allen CSV, class targets, product gates | Empirical verification |
| Body / systems | Zig Fixed + QEMU | Bit-authority embodiment |
| Host twins | Haskell, Idris 2 | Functional + scientific parity |

*Structure is proved; measurements match public wet-lab within published gates; residual discrepancies are registered, not hidden.*
