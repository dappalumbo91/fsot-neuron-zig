# FSOT language twins network

**One mind doctrine. Three programming languages. Same function. Same accuracy gates.**

This document is the **linking system** for the Zig authority and its language twins.  
Copy lives in each twin repo under `docs/LANGUAGE_TWINS_NETWORK.md`.

---

## The three repositories

| Role | Language | GitHub | Local (lab) |
|------|----------|--------|-------------|
| **Authority** | Zig 0.15+ | [fsot-neuron-zig](https://github.com/dappalumbo91/fsot-neuron-zig) | `I:\fsot-neuron-zig` |
| **Host twin** | Haskell (GHC 9.x) | [fsot-neuron-haskell](https://github.com/dappalumbo91/fsot-neuron-haskell) | `Desktop\FSOT NEURON haskell` |
| **Host twin + structure** | Idris 2 | [fsot-neuron-idris](https://github.com/dappalumbo91/fsot-neuron-idris) | `Desktop\FSOT NEURON idris` |

```text
                    FSOT law pin D1D38A
                    S = K(T1+T2+T3)
                           |
         +-----------------+-----------------+
         |                 |                 |
   [Zig authority]   [Haskell twin]    [Idris twin]
   Fixed SCALE=1e12  host Double twin  host + types
   QEMU bare metal   full Phase A      Phase A + DNA
   full modes        runnable gates    trinary proof
         |                 |                 |
         +--------+--------+--------+--------+
                  |
         Same product function:
         genetics-as-code · FI · organism ·
         intel-loop · compose · think · Allen readout
```

---

## What “twin” means

| Requirement | Meaning |
|-------------|---------|
| **Same law** | One FSOT scalar spine (pin D1D38A); not three theories |
| **Same genetics** | 64-codon PRIMARY map; ORF → expression → phenotype → FI |
| **Same units** | ISI **ms**, rate **Hz**, adapt **abs** (not percent theater) |
| **Same Phase A order** | organism → compose → intel-loop → think → (isi-ks when present) |
| **Same PASS lines** | Product gates print the same family of claim strings when green |
| **Runnable** | Each language has a `fsot_mind` / `fsot-mind` binary you can boot |

**Not twin:** bit-identical IEEE or Fixed words across languages. Zig Fixed SCALE=1e12 remains bit-authority for lattice dynamics. Twins prove **functional and scientific equivalence** on the same gates.

---

## Accuracy parity (measured lab)

Cross-language Phase A / product (2026-08-01 lab boot):

| Gate | Zig | Haskell | Idris |
|------|-----|---------|-------|
| Codon ATG / PRIMARY | PASS | PASS | PASS |
| Genetic FI / PV≫Pyr | PASS | PASS | PASS |
| Continuous organism | PASS | PASS | PASS |
| Compose multi-hop | PASS | PASS | PASS |
| Intel-loop train→sleep→prove | PASS | PASS | PASS |
| Continuous think probe | PASS | PASS | PASS |
| Allen ISI KS product | PASS | PASS | **PASS** |
| Class FI scalpel closed | PASS | *via isi-ks* | **PASS** |
| Every-cell Allen iron | PASS | *host twin path* | *host twin path* |
| QEMU bare metal | PASS | n/a | n/a |
| Think-hour 60 min | **PASS** | n/a (Zig authority) | n/a |

### Lean 4 stamp + scientific certificate (2026-08-01, post-closure)

| Verification class | Status |
|--------------------|--------|
| **Formula verification** (`scientific_panel_ok`, SCALE=1e12, free_params=0, pin D1D38A) | **PASS** — Lean 4.31.0, 0 `sorry` |
| **Archive / neural lake build** | **PASS** (2204 / 16 jobs) |
| **Empirical verification** (Allen ISI KS / class FI / Phase A) | **PASS ×3 languages** |
| **Zig think-hour** | **PASS** — see `data/results/THINK_HOUR_ANALYSIS.md` |
| **Stamp** | `LEAN4_STAMP:scientific_panel_ok:v4.31.0:0_sorry:mind_stack` |
| **Residuals** | D2 Fixed vs Double KS path (low); D5 Zig embodiment depth (expected) |

Full certificate: **`docs/CROSS_LANG_LEAN_SCIENTIFIC_CERTIFICATE.md`**  
Machine table: `data/results/CROSS_LANG_DISCREPANCY.json` · stamp: `data/results/LEAN4_STAMP.txt`

Reproduce:

```text
Zig:      fsot_mind phase path → fixed | compose | intel-loop | think | isi-ks
Haskell:  cabal run fsot-mind -- phase-a
Idris:    ./build/exec/fsot-mind phase-a
Lean:     formal/ lake build · archive 02_FSOT-2.1-Lean-Full lake build
```

---

## Language roles (honest)

| Language | Why it exists in the network |
|----------|------------------------------|
| **Zig** | Systems / bare metal / Fixed lattice / Windows plant I/O / full mode surface |
| **Haskell** | Pure host twin; full Phase A + isi-ks; rapid parity stress |
| **Idris 2** | Same Phase A + **type-checked DNA→trinary structure** (biological hygiene as proof) |

---

## Shared science stack (all three)

```text
DNA / class ORFs
  → PRIMARY trinary (A,G=+1 ; C,T=−1)
  → IUPAC AA + charge / aromatic
  → FSOT expression (φ, π, γ seeds)
  → phenotype FI knobs (no free tables)
  → organism · memory · intel · think
  → Allen ephys readout (native units)
```

Doctrine docs (per repo as available):

- `docs/GENETICS_AS_TRINARY_CODE.md` (Zig)
- `docs/DNA_TRINARY_FSOT.md` (Idris)
- `docs/PHASE_A_PARITY.md` (Haskell + Idris)
- `docs/FULL_CAPABILITY_PARITY.md` (twins)
- `docs/CLAIMS_AND_NONCLAIMS.md` (Zig)

---

## How to navigate from any README

1. Open this file: **`docs/LANGUAGE_TWINS_NETWORK.md`**  
2. Follow GitHub links to the other two repos  
3. Run that language’s `phase-a` / product gates  
4. Compare PASS lines — same function, same accuracy claims  

---

## Related FSOT GitHub (outside the three twins)

| Repo | Role |
|------|------|
| [FSOT-2.1-Lean](https://github.com/dappalumbo91/FSOT-2.1-Lean) | Law / Lean verification |
| [FSOT-2.1-Neural](https://github.com/dappalumbo91/FSOT-2.1-Neural) | Neural monorepo / wet-lab banks |

---

*Maintained with each twin release. If a gate is not PASS, it is not a shipping claim for that language.*
