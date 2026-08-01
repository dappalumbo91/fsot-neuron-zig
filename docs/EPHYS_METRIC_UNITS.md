# Ephys metric units — field-standard gates

**Repo:** fsot-neuron-zig  
**Status:** Binding for Allen / scalpel / bio_match reporting  
**Not:** percent-of-target as the primary gate label

---

## What the field uses

| Observable | Native unit | How papers report error |
|------------|-------------|-------------------------|
| Firing rate | **Hz** | mean ± SEM; absolute Δ Hz when matching a target mean |
| Interspike interval (ISI) | **ms** | ms (or s); absolute residual when locking to a target |
| Adaptation index | **dimensionless** | absolute |ΔA| (index is already a ratio) |
| Spike timing | ms | RMS / jitter in ms |
| Conductance / current | nS, pA | absolute SI units |

Computational-neuroscience model locks against Allen Cell Types (and similar public means) should therefore **gate in those units**, not “2%” as the headline claim. Relative residual may appear as a **diagnostic** (fractional residual), not as the gate name.

Percent-of-target is common in engineering QA; it is **not** the primary language of ephys figures.

---

## Primary gates (this repo)

**Doctrine:** **every cell** must sit inside these bounds — population mean alone is not enough (`all_units_closed`, `FSOT_EVERY_CELL_BIO_MATCH_OK`).

| Gate | Quantity | Tolerance (absolute) | Applies to |
|------|----------|----------------------|------------|
| ISI | \|ISI − Allen\| | **≤ 1.42 ms** | **each** FI unit |
| Adapt (pass) | \|A − Allen\| | **≤ 0.00512** | **each** FI unit (≥6 spikes) |
| Adapt (iron) | \|A − Allen\| | **≤ 0.00128** | polish target per unit |
| Rate | \|r − Allen_rate\| | **≤ 0.40 Hz** | **each** FI unit (Allen_rate = 1000/ISI_ms) |
| Rate band | mean / unit rate | **5–80 Hz** | safety envelope |
| Class Pyr | \|r − target\| | **≤ 0.33 Hz** | **each** Pyr replicate |
| Class PV | \|r − target\| | **≤ 1.67 Hz** | **each** PV replicate |
| Class SST | \|r − target\| | **≤ 0.59 Hz** | **each** SST replicate |
| Class VIP | \|r − target\| | **≤ 0.70 Hz** | **each** VIP replicate |

Code:

- `src/bio_probe_fixed.zig` — `ISI_TOL_MS`, `ADAPT_TOL_ABS`, `UNIT_RATE_TOL_HZ`, `polishAllUnits`, `all_units_closed`
- `src/scalpel_rate_fixed.zig` — `TOL_*_HZ`, `n_units_closed`, `max_unit_abs_err_Hz`

---

## Diagnostics (not gate labels)

| Symbol | Meaning |
|--------|---------|
| `isi_rel_err` / `isi_frac` | `isi_abs_err_ms / ALLEN_ISI_MS` |
| `adapt_rel_err` / `adapt_frac` | `adapt_abs_err / ALLEN_ADAPT` |
| class `rel_err` | `abs_err_Hz / target_Hz` |

These fractions exist for comparison with older logs and archive Python. **PASS/FAIL uses absolute native units only.**

---

## Full CSV variance (distribution match)

Mean-only lock is **not** the full Allen story. Public `ephys_features.csv` has large CV (ISI CV ~0.8). Protocol:

| Layer | Gate | File / mode |
|-------|------|-------------|
| Mean FI lock | every cell near bio_match mean | `bio_probe_fixed` · `fixed` |
| Class means | every Cre class replicate | `scalpel_rate_fixed` |
| **CSV variance** | specimen-mapped pop (256 stratified): mean/sd/quantiles + **KS** | `allen_dist_fixed` · `allen-dist` / `fixed` |
| **Cre-class variance** | Pyr / PV / SST / VIP each match mouse Cre dist + KS | `allen_class_dist_fixed` · `allen-class-dist` / `fixed` |

Snapshots under `data/allen/`:

- `allen_dist_targets.txt` — full-CSV mean, SD, SEM, quantiles  
- `allen_sample_256.txt` — stratified mouse Cre specimen sample  
- `class_{pyr,pv,sst,vip}_sample.txt` — per-class specimens  
- `class_dist_targets.txt` — per-class mean/sd/quantiles/rate  

**Per-cell:** residual vs **assigned specimen**.  
**Population / class:** |Δmean|, |Δsd|, quantiles, two-sample KS (ISI + adapt).

---

## Reproduce

```powershell
.\zig-out\bin\fsot_mind.exe fixed     # ISI ms + adapt abs + scalpel Hz
.\zig-out\bin\fsot_mind.exe scalpel
.\scripts\reproduce_bio_gates.ps1
```

Expect lines:

```text
isi_abs_err_ms=… adapt_abs_err=…
FSOT_EPHYS_NATIVE_UNITS_OK
Pyr … |Δ|=… Hz tol=… Hz
FSOT_SCALPEL_RATES PASS
```
