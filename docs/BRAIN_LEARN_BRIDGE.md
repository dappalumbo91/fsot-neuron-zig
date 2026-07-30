# Real-brain learning bridge

**Problem we fixed:** Experience teaching lived only in Python (`trace_bank.json`) while top-to-bottom stress ran Zig. Doctrine matched; **memory did not**.

**Solution:** `fsot_mind brain-learn` encodes school lessons into **OrganismF** (real genetic brain + episodic store + neuromod + sleep), then proves multi-hop claimability on that taught bank.

## Run

```powershell
cd I:\fsot-neuron-zig
# build mind, then:
fsot_mind brain-learn           # silent teach→practice→sleep→prove
fsot_mind brain-learn-speak     # same + English TTS of learned facts
fsot_mind english               # lexicon + Windows TTS (real words)
fsot_mind practice              # utter → TTS → self-hear → encode
# NOT for English: speakers = formant/DAC smoke only
```

## What touches the real brain

| Step | Mechanism |
|------|-----------|
| TRAIN | `organism.store.encode` + hipp/assoc drive under wake_encode neuromod |
| BANK | Declarative Q→A hashes for grounded multi-hop retrieve |
| PRACTICE | Probe dynamics + PE DA / re-encode on miss |
| SLEEP | NREM-like offline ticks on the **same** organism brain |
| PROVE | 1–3 hop claim chains must hit taught answers |
| SPEAK | Optional `host_tts_fixed.speakEnglish` (not formants) |

## Curriculum sources

1. **Embedded** in `src/brain_learn_fixed.zig` (literacy + math atomics + multi-hop chains)  
2. **File:** `data/curriculum/brain_teach/lessons.tsv` (`question \t answer \t fact`)  
3. **Export from monorepo experience school:**

```powershell
cd "I:\fsot nuron"
python scripts/export_brain_teach_bank.py
```

## Relation to Python hop traces

Python `trace_bank.json` remains a **companion capacity report** and can feed TSV via export.  
**Authority for live intelligence** is Zig `brain-learn` / `intel-loop` / `claim` on OrganismF.

## Gates (2026-07-30 first pass)

```
BRAIN_LEARN taught=53 file=11 eps=32 practice=42/42 acc=1.0
prove=20/20 claimable=20 prove_acc=1.0 claim_rate=1.0
FSOT_BRAIN_LEARN PASS
FSOT_REAL_BRAIN_TEACH_OK
```
