# FSOT Neuron Zig

**Fluid Spacetime Omni-Theory (FSOT) neural mind — Zig authority.**

**One law, many folds.** Cosmology and the neural mind share the **same** seed-derived scalar \(S=K(T_1+T_2+T_3)\) (pin **D1D38A**). This repo is the **silicon domain engine** for the neuroscience fold — not a second theory.

| Authority | Where |
|-----------|--------|
| **Physical Archive (offline master)** | `I:\FSOT-Physical-Archive` |
| **GitHub = archive / Lean verification** | [**FSOT-2.1-Lean**](https://github.com/dappalumbo91/FSOT-2.1-Lean) — public face of the Physical Archive |
| **Neural monorepo (Allen / wet-lab)** | [**FSOT-2.1-Neural**](https://github.com/dappalumbo91/FSOT-2.1-Neural) |
| **This repo (Zig mind body)** | Fixed lattice, genetics, wet cascade, think/sleep, organism |

Map: [`docs/ARCHIVE_PIN_AND_MIND_FOLD.md`](docs/ARCHIVE_PIN_AND_MIND_FOLD.md)

Bare-metal multi-region brain, 64-codon genetic spine, fixed-point lattice (SCALE=1e12), wet biophysics (stochastic AMPA/NMDA, spine cascade, glia, STDP), grade ladder PK→G8 (≥95% **on project gates**), paraphrase depth, all-atom MD lab (host f64), episodic 5W1H memory, machine language, English lexicon codec, TTS plant, live host senses.

Python is **optional host I/O only** (lexicon teacher / lab in the monorepo). The mind core runs in Zig without Python.

| | |
|--|--|
| **Theory / pin** | FSOT 2.1 — pin D1D38A ([FSOT-2.1-Lean](https://github.com/dappalumbo91/FSOT-2.1-Lean) + Physical Archive) |
| **Law path** | One scalar engine; cosmology = fold; mind = fold + domain engine (this repo) |
| **Embodiment authority** | Fixed-point lattice (`src/fixed.zig`, SCALE=1e12) |
| **Math solidification** | [`docs/FSOT_MATH_SYSTEM_SOLIDIFIED.md`](docs/FSOT_MATH_SYSTEM_SOLIDIFIED.md) |
| **Archive ↔ Zig map** | [`docs/ARCHIVE_PIN_AND_MIND_FOLD.md`](docs/ARCHIVE_PIN_AND_MIND_FOLD.md) · [`docs/ARCHIVE_ZIG_BIO_CROSSREF.md`](docs/ARCHIVE_ZIG_BIO_CROSSREF.md) |
| **Lean stamp (neural structure)** | monorepo `formal/` · `scientific_panel_ok` (0 sorry) |
| **Language** | Zig 0.15+ |
| **License** | Apache-2.0 |
| **Learned capacity** | [`docs/LEARNED_CAPACITY.md`](docs/LEARNED_CAPACITY.md) — Zig intel stack + companion multi-hop snapshot |
| **Top-to-bottom verify** | [`docs/TOP_TO_BOTTOM_VERIFICATION.md`](docs/TOP_TO_BOTTOM_VERIFICATION.md) — stress · QEMU · Lean stamp · bio |
| **Real-brain school** | [`docs/BRAIN_LEARN_BRIDGE.md`](docs/BRAIN_LEARN_BRIDGE.md) — `fsot_mind brain-learn` teaches **OrganismF** |
| **Lean × wet-lab cert** | [`data/results/LEAN_WETLAB_CERTIFICATE.md`](data/results/LEAN_WETLAB_CERTIFICATE.md) |
| **Related monorepo** | [FSOT-2.1-Neural](https://github.com/dappalumbo91/FSOT-2.1-Neural) (wet-lab / export banks) |

## Quick start

```bash
# Zig 0.15+ on PATH
zig build -Doptimize=ReleaseFast

# Mind host (fixed authority suite)
./zig-out/bin/fsot_mind all
```

### Windows (recommended if AV locks `zig-out`)

```powershell
$out = Join-Path $env:TEMP "fsot_mind_live.exe"
$cache = Join-Path $env:TEMP "fsot_zig_cache_live"
zig build-exe -OReleaseFast "-femit-bin=$out" --cache-dir $cache --name fsot_mind_live src/main_mind.zig -lgdi32 -luser32 -lwinmm

# Core language / knowledge gates
& $out machine-lang
& $out english
& $out practice
& $out grade
& $out mind          # full connected organism (BOOT_MIND.cmd)
& $out stress
```

Or double-click `BOOT_MIND.cmd` for the live organism.

## Modes (high-signal)

| Mode | What it tests |
|------|----------------|
| `ladder` / `straight-a` | PK→G8 STEM/literacy ≥95% per domain |
| `depth` / `understand` | Paraphrase held-out understand exam ≥95% |
| `pathways` / `glia` / `molecular` | Synaptic paths + STDP + wet cascade + glia |
| `md` / `allatom` | All-atom MD lab (water + K⁺ filter; not cognition) |
| `neuromod` | DA/ACh/NE/5-HT Fixed ODEs (systems neuromodulation) |
| `sleep` / `consolidate` | Offline sleep-like replay + STDP consolidation |
| `claim` / `claimability` | Multi-hop grounded claimability ≥95% (1–3 hops) |
| `intel-bio` | Full neuromod + sleep + claim stack |
| `intel-loop` | Closed train→retrieve→sleep→prove organism cycle |
| `brain-learn` | **Real-brain school** — encode lessons into OrganismF + sleep + multi-hop prove |
| `brain-learn-speak` | Same + English TTS of what was learned (not formant waves) |
| `english` / `practice` | Lexicon + Windows TTS; self-hear language loop |
| `speakers` | Formant/DAC smoke only — **not** English product path |
| `frontier` | Multi-day curiosity + sleep cycles; speech path flagged intact |
| `mnist` | Vision accuracy gate ≥95% (pack from monorepo) |
| `machine-lang` | Native tongue: TritWord FSOT frames generate/understand |
| `machine-lang-stress` | 1000-frame round-trip stress |
| `english` | Lexicon choose + TTS real words |
| `practice` | Utter → TTS → self-hear → encode |
| `novel` | Single complex inquiry → novel synthesis |
| `grade` | Legacy soft grade practice (prefer `ladder`) |
| `mind` | Live senses + attention + EN_SAY + machine frames |
| `stress` / `all` | Fixed suite gates |
| `teach` / `transfer` / `short-horizon` | Memory / learning |

## Architecture (fixed path)

- **Scalar / neuron / network / brain** — `*_fixed.zig`
- **Genetics** — 64-codon PRIMARY, ORF → expression → phenotype → `fsotPairWeight` W
- **Wet stack** — `channel_stoch_fixed` (48 AMPA / 16 NMDA / 50µs Markov) → `molecular_fixed` → `glia_fixed` → `stdp_fixed`
- **Pathways / concepts** — `synapse_path_fixed` (Hebb + STDP + novel bonds)
- **Curriculum** — `grade_ladder_fixed` PK–G8 · `understand_depth_fixed` · `mnist_accuracy_fixed`
- **All-atom MD lab** — `allatom_md.zig` (host f64 only)
- **Organism** — continuous tick + inject + modulation
- **Memory** — episodic fingerprints, 5W1H, curiosity
- **Machine language** — `machine_lang_fixed.zig` (native I/O tongue)
- **English codec** — `lexicon_en_fixed.zig` + `host_tts_fixed.zig`
- **Live plant** — display, mic, TTS, optional formant speech organ
- **Attention / scene** — EEG-anchored gates, ambient scene analysis

IEEE f64 modules remain **lab / parity** only (`float-lab`, `sme-float`, `md`).

## Language doctrine (short)

```text
Mind native tongue  = machine language (FSOT frames)
English             = codec (lexicon + TTS)
LLM / Ollama        = external teacher in monorepo only — not runtime mind
```

Details: [`docs/LANGUAGE_AND_SPEECH.md`](docs/LANGUAGE_AND_SPEECH.md)  
Full reproducible pipeline (lexicon growth, curriculum data, teacher scripts): monorepo  
[`docs/LANGUAGE_LEARNING_METHODOLOGY.md`](https://github.com/dappalumbo91/FSOT-2.1-Neural/blob/experiment/fsot-fixed-precision/docs/LANGUAGE_LEARNING_METHODOLOGY.md)

## Doctrine docs (repo only)

- **`docs/FSOT_MATH_SYSTEM_SOLIDIFIED.md`** — math used to build this system + archive bridge
- `docs/WHY_NOT_ALL_ATOM_MD.md` — MD is lab, not mind
- `docs/ZIG_MIND_AUTHORITY.md`
- `docs/FIXED_POINT_EXPERIMENT.md`
- `docs/TRINARY_BARE_METAL.md`
- `docs/GENOME_AS_CODE.md`
- `docs/BARE_METAL_IO.md`
- `docs/SPEECH_ORGAN_DOCTRINE.md`
- `docs/BIO_SENSORY_SYSTEM.md`
- `docs/HOST_IO_ZIG.md`
- `docs/LANGUAGE_AND_SPEECH.md`

Monorepo-only (Python host, Lean formal, wet-lab battery):  
`WET_BIOPHYSICS`, `GRADE_SCHOOL_DEPTH`, `SYNAPTIC_PATHWAYS`, `formal/`, wetlab certificate.

Do **not** put project docs on the Desktop. Authority lives in this repository.

## QEMU bare metal

```powershell
./run_qemu.ps1
```

Builds freestanding Multiboot kernel (`src/main_kernel.zig`) when QEMU is available.

## License

**Apache License 2.0** — see [`LICENSE`](LICENSE) and [`NOTICE`](NOTICE).

Copyright 2026 Damian Arthur Palumbo.

```
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0
```

Apache-2.0 includes an express patent grant (useful for neural / systems code). Seed constants and scalar law follow the FSOT methodology pin used in the monorepo.

