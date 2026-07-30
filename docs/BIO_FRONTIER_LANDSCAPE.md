# Bio frontier landscape — who else is here, what we measure

**Date:** 2026-07-30  
**Repo:** fsot-neuron-zig  
**Purpose:** Map related work and **which metrics fit our architecture** (not LLM leaderboards).

---

## Scope of *this* project (do not shrink it)

We are **not** a wet lab reusing nature’s finished tissue.  
We are **not** an LLM app glued to a chat UI.

We are building a **functioning neurological system in code**, from the ground up:

| Pillar | Meaning |
|--------|---------|
| **FSOT** | Fluid Space-time Omni Theory — mathematical background that **solidifies** dynamics, weights, and process (not free-parameter ML soup) |
| **Genetic substrate** | Trinary-ish genotype → pair weights → lattice — **code as genetics**, not DNA in a dish |
| **Bare metal depth** | Fixed-point lattice, host/kernel, plant I/O — **operating-system class mind**, not a high-level chatbot service |
| **Eventual silicon gates** | Path toward physical implementation; today: claimable soft organism |
| **Human capability target** | Learn from experience, think from what was learned, articulate, multi-turn exchange — **via the bio stack**, not a dialogue LLM |

### Why this is the harder job (honest)

| Approach | What they start with | What they must invent |
|----------|----------------------|------------------------|
| **Cortical Labs / wet MEA** | Neurons **nature already built** (cultured tissue) | Electrode I/O, closed-loop training, care of living cells |
| **LLM products** | Massive corpora + SGD | Token prediction apps; no genetic brain, no FSOT law |
| **This project** | **Empty silicon** + math + genotype doctrine | Rebuild neurological *function* from **observables + FSOT + genetic law**, encode/retrieve/sleep/motor, claimability |

Wet labs **borrow** the substrate. We **rebuild** it as a lawful computational organism. That is a different and, in software-theory terms, **deeper** engineering problem — and it drops **below** the level LLMs operate at (app layer vs neurological OS).

**Cortical Labs remains useful** as a *closed-loop learning* data source and existence proof that biological computation can act in a world — not as the same product class.

---

## 1. Live wet neurons on chips (related — different substrate)

### Cortical Labs (Melbourne) — DishBrain / CL1

| | |
|--|--|
| **Company** | [Cortical Labs](https://corticallabs.com) |
| **Hardware** | **CL1** — cultivated human neurons on multi-electrode array (MEA), closed-loop with software |
| **Famous demos** | **Pong** (2022, DishBrain; Nature Electronics) · **Doom** targeting/shooting (later CL1 demos) |
| **Route** | **Wet bio substrate nature grew** does the computation; silicon is I/O + world sim |
| **Public science** | Kagan et al., *Nature Electronics* (2022) — in vitro neurons learn goal-directed Pong via free-energy / predictability feedback |
| **Open bulk datasets?** | Methods + paper figures; **not** a plug-in leaderboard for our stack. Inspiration + task shape only. |

**What they measure (transferable idea):**

- Closed-loop: sense → spike → act → environment feedback  
- Learning as **improvement over random / control** under structured feedback  
- Goal-directed behavior with **few samples relative to deep RL**, not epoch corpora  
- Unpredictable stimulation as “error / free energy” signal (animal-like)

**How we differ (do not understate):**

| Cortical Labs | This project (FSOT Zig mind) |
|---------------|------------------------------|
| Live cultured neurons (nature’s hardware) | **Genetic Fixed lattice built from law** (FSOT + genotype) |
| Real MEA biophysics | STDP / neuromod / glia / molecular *process models* under **FSOT** |
| Wet matter as processor | **Rebuilt tissue-as-code** — no petri dish required |
| Games (Pong/Doom) as closed-loop | Full stack: school · self-study · think-from-memory · articulate · sleep · claimability · path to **chip gates** |

We are **not** competing on their wet hardware. We are doing the **software reconstruction of neurological systems** with a **named mathematical theory (FSOT)** as the solidifier — a harder, different job.

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
