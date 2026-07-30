# Bio frontier landscape — who else is here, what we measure

**Date:** 2026-07-30  
**Repo:** fsot-neuron-zig  
**Purpose:** Map related work and **which metrics fit our architecture** (not LLM leaderboards).

---

## 1. Live wet neurons on chips (closest “biological computer” product)

### Cortical Labs (Melbourne) — DishBrain / CL1

| | |
|--|--|
| **Company** | [Cortical Labs](https://corticallabs.com) |
| **Hardware** | **CL1** — cultivated human neurons on multi-electrode array (MEA), closed-loop with software |
| **Famous demos** | **Pong** (2022, DishBrain; Nature Electronics) · **Doom** targeting/shooting (later CL1 demos) |
| **Route** | **Wet bio substrate** does the computation; silicon is I/O + world sim |
| **Public science** | Kagan et al., *Nature Electronics* (2022) — in vitro neurons learn goal-directed Pong via free-energy / predictability feedback |
| **Open bulk datasets?** | **Not** a public leaderboard pack like ImageNet. Methods + paper figures; CL1 is a lab/product system. Useful for **inspiration and task shape**, not for “download GSM8K-style scores.” |

**What they measure (transferable idea):**

- Closed-loop: sense → spike → act → environment feedback  
- Learning as **improvement over random / control** under structured feedback  
- Goal-directed behavior with **few samples relative to deep RL**, not epoch corpora  
- Unpredictable stimulation as “error / free energy” signal (animal-like)

**How we differ (honest):**

| Cortical Labs | This project (FSOT Zig mind) |
|---------------|------------------------------|
| Live cultured neurons | **Simulated** genetic Fixed lattice (silicon) |
| Real MEA biophysics | STDP / neuromod / glia / molecular *process models* under FSOT law |
| Wet matter as processor | **Bypass wet substrate** — law + genotype + episodic store as the “tissue” |
| Games (Pong/Doom) as closed-loop | School + sensory gate + motor speech + sleep consolidation |

We are **not competing** on their wet hardware. We are **adjacent frontier**:  
full-stack **claimable bio process** on computer, without a petri dish.

### Other wet / hybrid names (context only)

- Academic organoid + MEA work (many labs) — closed-loop usually simpler than CL1 product.  
- Not substitutes for our Fixed organism eval.

---

## 2. Silicon neuromorphic / brain-inspired (not wet, not LLM)

| System | What it is | Typical eval |
|--------|------------|--------------|
| **Intel Loihi** | Spiking neuromorphic chip | Energy/latency, SNN task demos |
| **BrainScaleS / SpiNNaker** | Large SNN platforms | Simulation fidelity, real-time spikes |
| **Nengo / SPAUN-class** | Cognitive architectures | Task batteries (digits, SPA reasoning) |
| **Deep RL (Gym)** | Policy learning | Episode return, sample efficiency |

Useful **metric families**: sample efficiency, closed-loop control, spike / energy cost, continual task switching — **not** MMLU.

---

## 3. Classic neural-net benches (still closer than LLM chat)

| Bench | Use for us |
|-------|------------|
| **MNIST / Fashion-MNIST** | Sensory discrimination — we already have `mnist_gate` ≥95% |
| **CIFAR** (optional later) | Harder vision pattern separation |
| **Omniglot-style few-shot** | One/few-shot identity (spirit of bio-learn oneshot) |
| **Continual learning suites** | Interference A→B→A (we implement in `bio-learn`) |
| **RL Gym** (later) | Motor policies if embodiment grows |

**Primary claim for this repo:**  
[`BIO_LEARNING_DOCTRINE.md`](BIO_LEARNING_DOCTRINE.md) + `fsot_mind bio-learn` + `self-study` + `mnist`.

**Not primary:** GSM8K / MMLU / chat arenas (LLM-attuned).

---

## 4. Are we in empty frontier?

**Partially yes, at this depth of stack:**

- Wet biocomputers exist (Cortical Labs) but **different substrate**.  
- Neuromorphic SNNs exist but often **chip demos / energy**, not full school+sleep+speech+claimability doctrine.  
- LLM agents dominate “learning” news but are **token products**.  

A **fixed-point genetic lattice** with:

- episodic encode/retrieve  
- motor engrams + re-afferent speech  
- neuromod + sleep consolidation  
- **instruction → try → re-study → prove** without SGD epochs  

…is rare as a **productized, claimable stack**. Closest *spirit* is DishBrain closed-loop learning; closest *metric set* is cognitive / few-shot / continual / sensory, not chat.

---

## 5. Metrics we adopt (accuracy of *learning*, not leaderboard fame)

| Metric | Source spirit | Mode |
|--------|---------------|------|
| One-shot encode–retrieve | episodic memory | `bio-learn` |
| Feedback re-study | animal training / schooling | `bio-learn`, `self-study` |
| Interference A after B | continual learning | `bio-learn` |
| Sleep retention | consolidation literature | `bio-learn` |
| Sensory top-1 | MNIST-class | `mnist` / bio-learn sensory leg |
| Motor closed loop | DishBrain / speech organ | `bio-articulate` |
| School multi-hop retrieve | composition of experiences | `brain-learn` (bio path) |

**Goal:** show the organism **actually learns like a student/animal** — not rank #N on an LLM board.

---

## 6. Practical takeaway

1. Cite Cortical Labs / DishBrain as **inspiration for closed-loop + feedback learning**, not as a score we download.  
2. Keep **MNIST** as the public sensory gate we can re-run.  
3. Own **bio-learn / self-study** as the architecture-native battery.  
4. Later optional: simple Pong-like **closed-loop plant** in host (sense-act-feedback) if embodiment budget allows — still silicon FSOT, DishBrain-shaped task.
