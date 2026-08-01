# Forward intelligence — biological direction

**Date:** 2026-07-30  
**Status:** Implemented on Zig Fixed lattice (not LLM chain-of-thought).

This is the path after wet stack + math stamp: **process-accurate intelligence mechanisms**.

## Stack

| Layer | File | Role |
|-------|------|------|
| Neuromodulators | `neuromod_fixed.zig` | DA / ACh / NE / 5-HT first-order ODEs |
| Offline consolidate | `sleep_replay_fixed.zig` | Wake encode → rest → NREM → replay+STDP |
| Multi-hop claimability | `claimability_fixed.zig` | 1–3 hop grounded chains ≥95% (cues up front) |
| **Answer-dependent compose** | `compose_intel_fixed.zig` | Hop N from answer N−1 + WM + ablation + **schema discovery** + episodic-first |
| Combined gate | `fsot_mind intel-bio` | neuromod + sleep + claim + compose |
| Closed organism | `fsot_mind intel-loop` | train→sleep→prove **and** compose module gate |

## Biology (honest process scale)

| Mechanism | Biology | Our model |
|-----------|---------|-----------|
| ACh high at encode | Basal forebrain / attention | `wake_encode` tonic → encode gain |
| LC NE arousal | Locus coeruleus | External drive gain |
| DA tagging | VTA/SNc reward / salience | Pulses on encode + replay STDP η |
| 5-HT quiet | Raphe | Elevated in NREM; rest quiet gain |
| Sleep replay | Hippocampal–cortical reactivation | Soft fingerprint replay + STDP |
| Sigma proxy | Spindle-band association | `sigmaProxy(HT, low ACh, reactivate)` |
| Claimability | Premises must support claim | Every hop bank-grounded + taught answer |

**Not** wall-clock PC sleep. Schedule is **model-ms** (same doctrine as retention stage).

## FSOT coupling

- Time constants / scales: φ, ψ_con, η_eff (seed-derived)  
- STDP η: `1 + 0.8·DA + 0.4·ACh`  
- Encode gain: `(1+0.7·ACh)·(1+0.5·NE)`  
- Zero free LSQ parameters on the neuromod law path  
- Lean: `FSOTNeural.IntelBio` · folded into `scientific_panel_ok`

## Closed loop (train → sleep → prove)

Mode: **`intel-loop`** (`train-sleep-prove`, `loop`)

```text
TRAIN (wake_encode ACh/NE + DA tags)
  → SPACED RETRIEVAL (prediction-error DA on hit/miss)
  → PROBE_PRE (claimability + episodic top-1)
  → DELAY (wake_rest)
  → SLEEP (NREM + replay STDP)
  → PROVE (claim post + mem post + transfer chains)
```

Extras:

| Piece | Role |
|-------|------|
| Prediction-error DA | Correct retrieve → DA pulse; miss → NE reorient + re-encode |
| Working memory | 4 Fixed slots (limited capacity), decay over rest |
| Transfer probe | Cross-domain 2-cue items after sleep (≥80%) |

## Compositional hop (next layer after parallel claimability)

Mode: **`compose`** (`compose-intel`, `answer-hop`)

Parallel claimability lists all cues. Composition does **not**:

```text
seed cue only
  → retrieve answer A0  (encode under ACh; PE-DA on hit)
  → hold A0 in WM (≤4 slots)
  → method edge: answer word → next cue   (schema, not freestyle)
  → retrieve A1 … until N hops
  → claimable iff every hop grounded + final correct
ablation: corrupt intermediate → edge must break (proves dependence)
```

| Piece | Biology analogue |
|-------|------------------|
| Intermediate in WM | Limited-capacity hold of hop product |
| Answer → next cue edge | Hippocampal bind + associative re-cue |
| Ablation break rate | Causal check that hops are not independent |
| Schema discovery | Experience pairs strengthen answer→next-cue edges (co-occurrence) |
| Episodic-first | Hipp fingerprint retrieve preferred; bank is claim floor / fallback |
| Gate | claim ≥90%; ablation break ≥80%; ≥8 discovered edges; 2- and 3-hop activity |

**Honest non-claim:** discovered edges still come from a finite experience curriculum (not open-world web tool use). Stronger than static-only tables and stronger than parallel multi-cue lists.

**Ephys residual units** for the wet lattice (ISI ms, rate Hz, adapt abs) are separate: [`EPHYS_METRIC_UNITS.md`](EPHYS_METRIC_UNITS.md).

## Run

```powershell
cd I:\fsot-neuron-zig
.\zig-out\bin\fsot_mind.exe neuromod
.\zig-out\bin\fsot_mind.exe sleep          # consolidate / replay
.\zig-out\bin\fsot_mind.exe claim          # multi-hop claimability (parallel cues)
.\zig-out\bin\fsot_mind.exe compose        # answer-dependent composition + ablation
.\zig-out\bin\fsot_mind.exe intel-bio      # full stack (includes compose)
.\zig-out\bin\fsot_mind.exe intel-loop     # closed train→sleep→prove organism cycle
.\zig-out\bin\fsot_mind.exe stress         # fixed authority stress suite
```

### Multi-day curiosity frontier

Mode: **`frontier`** (`multi-day`, `curiosity-train`, `intel-frontier`)

```text
for day in 1..N:
  curiositySelect(weakest/novel) → ACh encode → PE retrieve → sleep → claim
then: ladder selfTest + depth (if bank) + speech path flag intact
```

Speech / mic / TTS fluent loop is **preserved** for reconnect: [`SPEECH_RECONNECT.md`](SPEECH_RECONNECT.md).

Expect:

```text
FSOT_NEUROMOD PASS
FSOT_SLEEP_REPLAY PASS / FSOT_CONSOLIDATION_OK
FSOT_CLAIMABILITY PASS / FSOT_MULTI_HOP_INTEL_OK
FSOT_COMPOSE_INTEL PASS / FSOT_ANSWER_DEPENDENT_HOP_OK / FSOT_COMPOSE_ABLATION_OK
FSOT_INTEL_BIO_STACK PASS
FSOT_INTEL_LOOP PASS / FSOT_TRAIN_SLEEP_PROVE_OK
FSOT_INTEL_FRONTIER PASS / FSOT_MULTI_DAY_CURIOSITY_OK
FSOT_SPEECH_PATH_INTACT
```

## How this ties to curriculum depth

```text
teach STEM/literacy (ladder/depth bank)
  → encode under ACh/NE (+ DA tag)
  → multi-hop claim chains (claimability)
  → offline replay consolidates W + fingerprints
  → re-probe retention + understand paraphrases
```

Wet cascade (channels → molecular → glia → STDP) remains the **synaptic** substrate;  
neuromod + sleep are the **systems-level** intelligence schedule on top of it.

## Lean stamp

`formal/FSOTNeural/IntelBio.lean` — 4 neuromods, 5 phases, replay+STDP, claim ≥95%, 0 free params.
