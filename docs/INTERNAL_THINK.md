# Internal thinking loop

**Mode:** `fsot_mind think` · `think-hour` · `boot-think`  
**Code:** `src/internal_think_fixed.zig`

## What it is

An **organism-side** loop that processes stored knowledge the way a human
brainstorms and checks themselves — **not** an LLM chain-of-thought string.

```text
BOOT: study world facts (wet encode) → NREM + wet maintenance
loop:
  RETRACE      re-walk cues → re-retrieve → verify engram match
  DISCOVER     unknown words → query tool → wet re-study
  LTM WARM     cold disk grown → STM re-encode
  BRAINSTORM   compose idea only from two grounded retrieves
  SELF-CORRECT on fail → re-experience truth; reject ungrounded idea
  CURIOSITY    fill open 5W1H slots on recent episode
  SLEEP        wake_rest → NREM → wet_maint → replay (CPU or VRAM deep)
```

**Wet encode** (`src/wet_encode_fixed.zig`): every `studyFact` runs neuromod →
network step → glia → molecular tagCoactive (stochastic channels) → STDP
modulated by glia×eligibility → consolidateToW → prune/myelo. CPU Fixed
lattice; GPU is for deep VRAM consensus, not spine Markov.

## Scientific method mapping

| Step | Organism |
|------|----------|
| Hypothesis | brainstorm compose from memory A + B |
| Test | re-retrieve A and B; both must match |
| Reject | ungrounded → `n_ideas_rejected`, re-study missing |
| Accept | encode idea episode + motor speak |
| Correction | failed retrace/cross → `studyFact` again |

## Long run

```text
fsot_mind think              # one probe cycle after boot
fsot_mind think-hour         # 60 wall-clock minutes
fsot_mind think-min 15       # 15 minutes
fsot_mind boot-think         # bio-learn + study + converse + think probe + 60 min
fsot_mind boot-think 60      # same, minutes optional
```

Heartbeat every 30s: cycles, retrace, cross, ideas, self-corrects, sleep, eps.

## Relation to EEG

Uses encode-drive from `eeg_gate_anchors` (SME spirit) during study/correct.
Phase discipline still applies when ideas are spoken (meaning before motor).
