# Biological accuracy research direction

**Date:** 2026-08-01  
**Scope:** Refine Zig · Haskell · Idris (and Python host twin) toward **connective / glial / internal-speech** biology — not LLM training.  
**Trigger:** public discussion of neural self-talk ([AstronomyVibes / related neuroscience framing](https://x.com/AstronomyVibes/status/2083654576092393522)) + recent glia / astrocyte literature.

---

## 1. What the self-talk claim actually points at

The viral framing (“brain cells are influenced by self-talk”) is **popular science compression**. The useful scientific targets underneath are:

| Real process | Neuroscience handle | FSOT map today | Accuracy upgrade |
|--------------|---------------------|----------------|------------------|
| **Internal speech / covert language** | Inner speech networks; OpenNeuro thinking-out-loud EEG | speech-EEG phase order; bio-converse | Explicit **covert think** path (no TTS) as primary; overt speak secondary |
| **Self-generated language → attention / affect / behavior** | Top-down control, ACh/DA modulation, prediction error | neuromod · curiosity · pending questions | Self-cue as **afferent-from-self** (re-entrant), not external teacher only |
| **Thought content shapes circuit gain** | State-dependent plasticity; arousal; engram allocation | encode_open · SME spirit · sleep | **Self-talk episode** → DA/ACh pulse → stronger encode when meaning aligns |
| **Not magic affirmation** | Needs action + feedback | bio-learn feedback loop | Keep “try → miss → re-experience” as law |

**Doctrine fit:** humans do not primarily “think words,” but **internal speech is a real control channel** over attention, emotion, and memory allocation. That is **re-entrant self-sensing**, not a chat API.

---

## 2. Similar study directions that raise biological accuracy

### 2.1 Astrocytes as memory co-computers (high priority)

Neuron-only nets under-model real tissue. Recent lines:

| Finding class | Implication for FSOT | Source class |
|---------------|----------------------|--------------|
| Astrocyte **Ca²⁺** recruited/refined during learning | Glia is not decoration — **state variable of encode/consolidate** | Holt et al. Trends Neurosci-style reviews; CA1 Ca imaging |
| Astrocytes contact ~10⁵ synapses; spatial Ca **surge threshold** | Glia integrates many synapses → multi-neuron association | Lines et al. eLife preprint class |
| Neuron–astrocyte nets store **more** memories than neuron-only (DenseAM-like) | Capacity growth via **glia-mediated multi-way association**, not only more synapses | IBM / PNAS neuron–astrocyte associative memory work |
| Peri-engram astrocytes; glia in consolidation | Sleep/replay should **tag glia eligibility**, not only STDP W | Nature spatial transcriptomics engram–glia (Sun et al. class) |
| Stochastic spontaneous astrocyte activity stabilizes circuits | Noise source is **functional**, not pure defect | PNAS 2025 spontaneous astrocyte activity class |

**Already in Zig authority (partial):** `glia_fixed`, wet cascade, sleep_replay, neuromod.  
**Gap:** twins under-implement glia; Ca surge / multi-way association not a product gate yet.

**Upgrade gates (proposed, all languages):**

```text
FSOT_GLIA_CA_SURGE_OK     — eligibility integrates multi-unit coactivity → glia Ca state
FSOT_GLIA_CONSOLIDATE_OK  — sleep uses glia-tagged synapses preferentially
FSOT_ASSOCIATIVE_CAPACITY_OK — memory capacity with glia > neuron-only baseline (measured)
```

### 2.2 Dendritic / spine computation

| Direction | FSOT map |
|-----------|----------|
| Local spine Ca → branch computation | `molecular_fixed` / spine cascade already lab-side |
| Not point-neuron only | Keep Fixed units but allow **branch eligibility** in wet path |

### 2.3 Learning-catch (already packaged in Phase D)

| Direction | Doc |
|-----------|-----|
| SME θ/γ at successful encode | `LEARNING_CATCH_EMPIRICAL_MAP.md` |
| NREM spindle–replay | think-hour / sleep residual |
| P300/N400 order | bio-converse phase_ok |

### 2.4 Internal speech as biological I/O

| Direction | FSOT map |
|-----------|----------|
| Covert speech EEG (OpenNeuro) | speech-eeg metrics; phase C |
| Self-hear re-afferent | bio-io / articulate |
| **New:** self-talk loop without partner | `internal_think` + engram utter + re-encode as **self-dialogue episode** |

---

## 3. Ranked roadmap (biological accuracy, all languages)

| Priority | Work item | Why |
|----------|-----------|-----|
| **P0** | Full **material / curriculum surface** on every host twin | Haskell/Idris missing depth of Zig banks → accuracy of *experience* suffers before glia math |
| **P1** | **Glia Ca product gate** (shared claim lines Zig/Haskell/Idris/Python) | Strongest recent accuracy lever vs neuron-only AI |
| **P2** | **Self-talk / re-entrant internal speech** mode | Aligns with self-talk literature without mysticism |
| **P3** | Associative capacity measure (with vs without glia) | Empirical capacity claim, not parameter theater |
| **P4** | Learning-catch feature pack from public EEG stats | Phase D map → measured band priors |
| **P5** | Capacity N/synapses under genetics | Connective density for freeform cascade |

**Law constraints unchanged:** pin D1D38A · SCALE=1e12 · free_params=0 · genetics-as-code · **local** binaries · no server mind.

---

## 4. Twin material coverage (honest)

| Layer | Zig | Haskell | Idris | Python (new host twin) |
|-------|-----|---------|-------|-------------------------|
| Phase A–D product gates | full Fixed depth | process gates green | process gates green | target: same gates, local |
| Curriculum / lexicon / LTM banks | rich on disk | **partial** | **partial** | copy shared `data/` |
| Glia / molecular wet | implemented | thin / stub risk | thin | port process first |
| GPU / QEMU / plant I/O | authority | n/a or stub | n/a | optional host only |
| Think-hour wet stack | measured PASS | probe-scale | probe-scale | probe → optional long |

**Haskell issue you noticed:** module *names* may mirror Zig, but **data materials** (curriculum banks, lexicon depth, LTM, MNIST pack, literature cards) and **deep wet/glia paths** are not fully exercised. Process gates can PASS on simplified stores while the *experience surface* is thinner. Fix = shared `data/` + deep port of L6–L8 layers, not more claim theater.

---

## 5. Python twin role

**Why Python:** scientists and tools live there; usability dissemination (your multi-language ship doctrine).  
**What it is not:** a server LLM API.  
**What it is:** **local** `fsot-mind` CLI twin (Apache-2.0), same phase-a…d, same genetics/Allen product claims, shared data trees.

Repo target: Desktop / GitHub `fsot-neuron-python` · local venv · no network required for core gates.

---

## 6. References (starting set — expand offline)

1. Self-talk / cognitive control popular framing: [X post AstronomyVibes 2083654576092393522](https://x.com/AstronomyVibes/status/2083654576092393522) — use only as **pointer** to internal-speech + top-down modulation, not as a primary paper.  
2. Astrocyte Ca plasticity in learning — Holt / Trends Neurosci-class reviews (2025–2026).  
3. Spatial threshold for astrocyte Ca surge — Lines et al., eLife reviewed preprint class.  
4. Neuron–astrocyte memory capacity / DenseAM analogy — PNAS / IBM Research technical notes (2024–2025).  
5. Peri-engram astrocytes / memory consolidation — Nature spatial transcriptomics (Sun et al. class).  
6. Spontaneous astrocyte activity in circuit stability — PNAS 2025 class.  
7. SME / speech-EEG / OpenNeuro — already in `LEARNING_CATCH_EMPIRICAL_MAP.md`, `SPEECH_EEG_METRICS.md`.

**Citation practice:** formula verification stays Lean; these items are **empirical direction** for wet/glia/self-talk gates.

---

*Living direction doc — update when glia or self-talk product gates land on all twins.*
