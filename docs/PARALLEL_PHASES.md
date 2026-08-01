# Parallel phases — Zig · Haskell · Idris

**Doctrine:** all three languages stay at the **same stage**.  
Run each phase **in parallel** across the trio; only advance when **all three** are green (or residual is Zig-only by design).

**Law:** pin D1D38A · SCALE=1e12 · genetics-as-code · free_params=0 · not LLM training.

---

## Stage map

| Phase | Name | Goal | Shared gates | Zig-only extras |
|-------|------|------|--------------|-----------------|
| **A** | Continuous organism product | Organism · compose · intel-loop · think · isi-ks · scalpel | **PASS ×3** | QEMU bare metal |
| **B** | Experience intelligence | One-shot · feedback · interference · transfer · sleep · motor | **PASS ×3** | MNIST pack, full wet, brain-learn depth |
| **C** | Embodied I/O | bio-io · articulate · converse · speech-EEG phase order | **PASS ×3** | GDI/mic/TTS plant depth on Zig |
| **D** | Scientific packaging | Cross-lang certificate · Lean stamp · EEG/MRI learning-catch citations | next | archive lake build |

**Stress:** every phase ends with a short product residual (Phase A suite or isi-ks) so gates do not regress.

---

## Phase A — DONE (all three)

```text
genetic/scalpel → organism → compose → intel-loop → think → isi-ks
FSOT_PHASE_A PASS ×3
```

---

## Phase B — Experience intelligence (current)

Animal/human learning process — **not** GSM8K/MMLU.  
Doctrine: [`BIO_LEARNING_DOCTRINE.md`](BIO_LEARNING_DOCTRINE.md)

| Subgate | Criterion |
|---------|-----------|
| One-shot | ≥75% after one experience |
| Feedback re-study | second ≥ first and ≥75% |
| Interference | A still ≥70% after B |
| Transfer / studied structure | ≥70% |
| Sleep retention | post ≥ pre − 1 item |
| Motor | ≥1 articulate path on correct recall |
| Not LLM | claim line `FSOT_NOT_LLM_BENCHMARK_OK` |

### Commands (parallel)

```text
Zig:      fsot_mind phase-b     # or: bio-learn ; self-study
Haskell:  cabal run fsot-mind -- phase-b
Idris:    ./build/exec/fsot-mind phase-b
```

Order inside `phase-b`:

1. B1 bio-learn (experience intelligence suite)  
2. B2 stress residual = short Phase A product (organism/compose or isi-ks when cheap)  
3. Print `FSOT_PHASE_B PASS` only if both green  

---

## Phase C — Embodied I/O (current / parallel)

| Subgate | Meaning |
|---------|---------|
| Bio-io path | visual/audio/intero inject spikes · speak re-afferent |
| Bio-articulate | teach → retrieve → motor utter → self-hear |
| Bio-converse | multi-turn think-from-memory · speech-EEG phase order |
| Speech-EEG phase order | attend → meaning → motor → self-hear → encode (SME spirit) |

### Commands (parallel)

```text
Zig:      fsot_mind phase-c
Haskell:  cabal run fsot-mind -- phase-c
Idris:    ./build/exec/fsot-mind phase-c
```

Zig has full Fixed plant (pathways/speech organ); host twins implement the **same process claim lines** with organism store + modality tags (GDI/mic/TTS remain Zig plant depth).

---

## Phase D — Scientific packaging (parallel)

| Deliverable | All three |
|-------------|-----------|
| Cross-lang certificate | `docs/CROSS_LANG_LEAN_SCIENTIFIC_CERTIFICATE.md` |
| Lean stamp | `LEAN4_STAMP:scientific_panel_ok:…` |
| Learning-catch data map | SME θ/γ · NREM · OpenNeuro inner speech |
| Phase matrix published | this file + results logs |

---

## Parallel lab workflow

```text
for each phase P in [B, C, D]:
  start Zig, Haskell, Idris work on P simultaneously
  measure gates on each
  close cross-lang discrepancies before starting P+1
  stress residual Phase A product
  commit + push all three
```

**Never:** finish Phase C only on Zig while twins sit on Phase A.

---

## Results paths

| Lang | Phase B log |
|------|-------------|
| Zig | `data/results/PHASE_B_*.txt` |
| Haskell | `data/results/PHASE_B_*.txt` |
| Idris | `data/results/PHASE_B_*.txt` |

---

*Maintained with each phase close. Same stage · same function · parallel execution.*
