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

| Gate | Quantity | Tolerance (absolute) | Source of magnitude |
|------|----------|----------------------|---------------------|
| Pop ISI | \|ISI − Allen\| | **≤ 1.42 ms** | ≈ former 2% of Allen ISI ~70.60 ms |
| Pop adapt (pass) | \|A − Allen\| | **≤ 0.00512** | ≈ former 10% of Allen A ~0.05115 |
| Pop adapt (iron) | \|A − Allen\| | **≤ 0.00128** | ≈ former 2.5% polish target |
| Rate band (pop FI) | mean rate | **5–80 Hz** | envelope during lock (not % of one mean) |
| Class Pyr | \|r − target\| | **≤ 0.33 Hz** | ≈ former 2% of ~16.35 Hz |
| Class PV | \|r − target\| | **≤ 1.67 Hz** | ≈ former 2% of ~83.35 Hz |
| Class SST | \|r − target\| | **≤ 0.59 Hz** | ≈ former 2% of ~29.54 Hz |
| Class VIP | \|r − target\| | **≤ 0.70 Hz** | ≈ former 2% of ~34.82 Hz |

Code:

- `src/bio_probe_fixed.zig` — `ISI_TOL_MS`, `ADAPT_TOL_ABS`, `ADAPT_TIGHT_ABS`
- `src/scalpel_rate_fixed.zig` — `TOL_*_HZ`, `abs_err_Hz`

---

## Diagnostics (not gate labels)

| Symbol | Meaning |
|--------|---------|
| `isi_rel_err` / `isi_frac` | `isi_abs_err_ms / ALLEN_ISI_MS` |
| `adapt_rel_err` / `adapt_frac` | `adapt_abs_err / ALLEN_ADAPT` |
| class `rel_err` | `abs_err_Hz / target_Hz` |

These fractions exist for comparison with older logs and archive Python. **PASS/FAIL uses absolute native units only.**

---

## Honest bounds

- Tolerances are **lock criteria** for model–mean agreement, not claims that biology is that precise across cells (CV of rates across neurons is often much larger).
- We do **not** claim SEM-matched full ISI distributions or KS tests against whole Allen CSV unless a protocol is added and measured.
- Biochemical cascade modules (`channel_stoch`, molecular) report counts and rates in their own process units; they are not re-expressed as “% error” of Allen FI.

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
