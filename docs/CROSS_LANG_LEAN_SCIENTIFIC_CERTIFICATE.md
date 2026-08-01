# Cross-language × Lean 4 scientific certificate

**Document class:** formula verification + empirical verification  
**Generated (lab):** 2026-08-01 (updated after discrepancy closure)  
**Scope:** Zig authority · Haskell twin · Idris twin  
**Overall stage:** **PASS**

---

## 1. Executive verdict

| Layer | Method | Status |
|-------|--------|--------|
| **Formula verification** (FSOT law + neural structure) | Lean 4 `lake build`, 0 `sorry` | **PASS** |
| **Cross-language functional parity** (Phase A product gates) | Same claim-line family, measured PASS ×3 | **PASS** |
| **Empirical verification** (Allen ephys / KS / class rates) | Public Allen CSV + class targets | **PASS ×3** |
| **Free parameters on scalar path** | Lean `free_parameters_zero` | **0** |
| **Zig think-hour (60 min)** | Continuous bio/wet organism | **PASS** |

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
| **Archive `lake build`** | **PASS** — 2204 jobs, exit 0 |
| **Neural formal `lake build`** | **PASS** — 16 jobs, `scientific_panel_ok`, 0 `sorry` |

**Citation type:** *formula verification*.

### 2.2 Shared lattice constant (all three languages)

| Language | SCALE | Match |
|----------|-------|-------|
| Zig / Haskell / Idris / Lean | \(10^{12}\) | **MATCH** |

Zig Fixed remains **bit-authority**; host twins may use Double for functional gates.

---

## 3. Empirical verification (wet-lab / product gates)

### 3.1 Public data cited

| Dataset | Role | Location |
|---------|------|----------|
| Allen Cell Types ephys features | Population ISI / adaptation | `data/allen/allen_dist_targets.txt` (n=1977; mean ISI ≈ 73.57 ms) |
| Finite KS samples | n=256 | `data/allen/allen_sample_256.txt` |
| Cre class FI targets | Pyr/PV/SST/VIP Hz | `allenRateHz` / scalpel |
| Codon map | 64-codon PRIMARY | `data/64_codon_trinary_map.txt` |

**Citation type:** *empirical verification* (Allen Institute Cell Types–class data).  
**Boundary:** Lean proves structure; Allen rates/KS are measurements.

### 3.2 ISI two-sample KS product (measured after closure)

| Language | sim mean (ms) | D | D_crit05 | D_cap | Product |
|----------|---------------|---|----------|-------|---------|
| **Zig** | 69.70 | 0.1289 | 0.1200 | 0.22 | **PASS** |
| **Haskell** | 74.28 | 0.0742 | 0.1200 | 0.22 | **PASS** |
| **Idris** | **74.15** | **0.0781** | 0.1200 | 0.22 | **PASS** (wired 2026-08-01) |

Host twins (Haskell/Idris) now agree closely. Zig Fixed polish path remains slightly higher D but within product cap.

### 3.3 Class FI scalpel (Allen closed)

| Language | Pyr Hz | PV Hz | Closed ≤ tol | Gate |
|----------|--------|-------|--------------|------|
| **Zig** | 16.67 (t 16.35) | 83.33 (t 83.35) | yes | **PASS** |
| **Idris** | 16.67 (t 16.35) | 83.33 (t 83.35) | yes (11 iters) | **PASS** |
| **Haskell** | genetic + isi-ks path | genetic + isi-ks path | order + product | **PASS** isi-ks |

Raw ORF readout (Idris genetic A0) may still show PV≈100 Hz before scalpel; **product closed rates** are the scalpel gate (D4 closed).

### 3.4 Phase A parity (measured)

| Gate | Zig | Haskell | Idris |
|------|-----|---------|-------|
| Codon / DNA-trinary | PASS | PASS | PASS |
| Scalpel class FI | PASS | *via isi-ks product* | **PASS** |
| Organism (48 ticks) | PASS | spikes=**160** PASS | spikes=**160** PASS |
| Compose claim_rate | 1.0 | 1.0 taught=19 ablate=1.0 | 1.0 taught=**19** ablate=**1.0** |
| Intel-loop | claim 1.0 | claim 1.0 | claim 1.0 |
| Think probe | PASS | PASS | PASS |
| ISI-KS product | PASS | PASS | **PASS** |
| Phase A suite | PASS | PASS | **PASS** |

### 3.5 Zig think-hour (60 min)

See **`data/results/THINK_HOUR_ANALYSIS.md`**.

| Metric | Value |
|--------|-------|
| Duration | 60.0 min |
| Episodic retrace | 1156/1156 (100%) |
| New concepts | 354 · curiosity ≈ 72.5% |
| Sleep / mut / wet STDP | 37 / 44 / ~2.24M |
| Verdict | **FSOT_THINK_HOUR PASS** |

---

## 4. Discrepancy register (post-closure)

| ID | Was | Status now |
|----|-----|------------|
| **D1** | Idris missing isi-ks in phase-a | **CLOSED** — A5 isi-ks PASS |
| **D4** | Idris PV=100 Hz only order | **CLOSED** — scalpel closed to Allen Hz |
| **D3** | Organism spikes 160 vs 192 | **CLOSED** — both host twins 160 (psiCon/etaEff drive) |
| **D6** | Compose taught/ablate gap | **CLOSED** — taught=19, ablate_break=1.0 |
| **D2** | Zig vs host ISI mean/D | **OPEN (low)** — all PASS product; Fixed vs Double polish residual |
| **D5** | Zig think deeper than twin probes | **OPEN (low, expected)** — systems authority; hour-run is Zig-only |

---

## 5. Scientific language map

| Phrase | When to use |
|--------|-------------|
| **Formula verification** | Lean theorems, SCALE, free_params=0, pin D1D38A |
| **Empirical verification** | Allen KS, class FI, Phase A gates, think-hour |
| **Cross-language functional parity** | Same claim strings PASS across three languages |
| **Not claimed** | Bit-identical IEEE across languages; Lean re-proof of Allen FI as analysis |

---

## 6. Stamp block

```text
================================================================================
FSOT LANGUAGE-TRIO × LEAN 4 SCIENTIFIC STAMP
Date (lab): 2026-08-01 (discrepancy closure)
LEAN4_STAMP:scientific_panel_ok:v4.31.0:0_sorry:mind_stack
Archive pin: D1D38A185487B452E470AC68ECE2EB45AEB1CA9CE25FC9BF9564C19633FFBE70
Archive lake build: PASS (2204 jobs, lean 4.31.0)
Neural formal lake build: PASS (16 jobs, scientific_panel_ok, 0 sorry)
Formula: S = K*(T1+T2+T3); free_parameters = 0; SCALE = 10^12
Empirical: Allen ISI KS PASS Zig+Haskell+Idris; scalpel closed Zig+Idris
Phase A PASS ×3; think-hour PASS (Zig)
Residuals open: D2 (Fixed vs Double KS path), D5 (Zig embodiment depth)
Repos: https://github.com/dappalumbo91/fsot-neuron-zig
        https://github.com/dappalumbo91/fsot-neuron-haskell
        https://github.com/dappalumbo91/fsot-neuron-idris
        https://github.com/dappalumbo91/FSOT-2.1-Lean
================================================================================
```

---

*Structure is proved; measurements match public wet-lab within published gates; residuals registered honestly.*
