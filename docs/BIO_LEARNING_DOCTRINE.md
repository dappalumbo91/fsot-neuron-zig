# Bio learning doctrine — not LLM benchmarks

**Repo:** fsot-neuron-zig  
**Status:** Binding doctrine for evaluation and teaching.

---

## The problem with LLM benchmarks

GSM8K, MMLU, chat-style Q→A, and next-token leaderboards measure **language-model products**:

- massive corpus pretraining  
- epoch / gradient training  
- token prediction as the skill  

That is a **different architecture**. Using those scores as the main north star **confuses** a biologically accurate organism with a chatbot. We stop treating them as the primary claim.

Secondary optional reference (honest, not primary): math *experience* transfer may be logged in companion monorepo reports — never as “we are an LLM that scores X on GSM8K.”

---

## What neural nets / brains are actually tested on

| Family | Examples | What it measures | Maps to us |
|--------|----------|------------------|------------|
| **Sensory discrimination** | MNIST, Fashion-MNIST, CIFAR-class | Pattern separate / classify from senses | `mnist_gate`, vision inject, pathways |
| **Episodic memory** | Encode–retrieve probes, delay match | Hippocampal-style storage & recall | `memory_fixed` encode/retrieve |
| **Few-shot / one-shot** | Omniglot-style, single experience | Learn from **few exposures**, not epochs | one-shot teach → prove |
| **Continual / interference** | Sequential tasks A then B | Remember A after learning B | multi-block encode + re-probe A |
| **Transfer / composition** | Same rule, novel instance | Generalize structure | multi-hop chains on **new** cues |
| **Motor / closed loop** | RL Gym, self-hear, sensorimotor | Act → sense consequence → adapt | `speakNow`, self-hear, adaptSpeech |
| **Sleep consolidation** | Wake encode → offline → probe | Replay / NREM benefit | `sleep_replay`, bio-articulate sleep |
| **Instruction + practice** | Teacher presents; learner tries; error re-study | Human/animal schooling, **not** SGD epochs | teach → probe → miss → re-experience |

Classic **CNN/MLP** benches (MNIST accuracy) and **RL** benches (Gym return) are closer in spirit than **LLM** benches. Cognitive / computational-neuroscience probes (encode–retrieve, pattern separation, consolidation) are closer still.

---

## How animals and humans learn (target process)

```text
INSTRUCTION / MATERIAL  (once or few times — experience)
        ↓
   ATTEND + ENCODE      (wake, neuromod, episodic + motor engram)
        ↓
   TRY / ACT            (retrieve → answer / motor / choice)
        ↓
   FEEDBACK             (correct → DA pulse; miss → re-experience)
        ↓
   REST / SLEEP         (offline densify — not "another epoch of gradient")
        ↓
   PROVE / TRANSFER     (same mind, novel instance or delayed probe)
```

**Not required for claimable bio learning:**

- thousands of SGD epochs over a corpus  
- hand-built regex solvers as “intelligence”  
- hash-bank `bankGet` as the mind  
- conversational LLM layers  

**Allowed:**

- teacher presents structured material (like a book or lesson)  
- self-study loop: re-read cue → try → check against experience  
- later: external API as *library access* for facts — only after this loop works  

---

## Modes

| Mode | Role |
|------|------|
| `fsot_mind bio-learn` | Full animal/human-style eval suite (primary) |
| `fsot_mind bio-articulate` | teach → sleep → cue → motor → self-hear |
| `fsot_mind brain-learn` | school on OrganismF via **retrieve** prove |
| `fsot_mind mnist` / gate | sensory discrimination (if pack present) |

---

## Pass criteria (bio-learn)

1. **One-shot:** ≥75% correct after **one** experience per item (no multi-epoch train loop).  
2. **Feedback re-study:** miss → one re-experience → second try improves.  
3. **Interference:** after block B, block A still ≥70%.  
4. **Transfer:** novel numbers/cues with same structure ≥70%.  
5. **Sleep:** post-sleep probe does not collapse (retention ≥ pre-sleep − 10 pts).  
6. **Motor:** at least one correct recall drives `speakNow` / engram.  

No GSM8K required to pass.
