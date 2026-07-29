# FSOT Neuron Zig

**Fluid Spacetime Omni-Theory (FSOT) neural mind — Zig authority.**

Bare-metal multi-region brain, 64-codon genetic spine, fixed-point lattice (SCALE=1e12), episodic 5W1H memory, curiosity, transfer, teach, modulate, SME bands, machine language, English lexicon codec, TTS plant, PK/K/G1 knowledge practice, live host senses, and short-horizon learning.

Python is **optional host I/O only** (lexicon teacher / lab in the monorepo). The mind core runs in Zig without Python.

| | |
|--|--|
| **Theory** | Fluid Spacetime Omni-Theory (FSOT) 2.1 |
| **Authority** | Fixed-point lattice (`src/fixed.zig`) |
| **Language** | Zig 0.15+ |
| **License** | Apache-2.0 |
| **Related monorepo** | [FSOT-2.1-Neural](https://github.com/dappalumbo91/FSOT-2.1-Neural) |

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
| `machine-lang` | Native tongue: TritWord FSOT frames generate/understand |
| `machine-lang-stress` | 1000-frame round-trip stress |
| `english` | Lexicon choose + TTS real words |
| `practice` | Utter → TTS → self-hear → encode |
| `novel` | Single complex inquiry ? novel synthesis |
| `grade` | PK/K/G1 teach facts → quiz → solve problems |
| `mind` | Live senses + attention + EN_SAY + machine frames |
| `stress` / `all` | Fixed suite gates |
| `teach` / `transfer` / `short-horizon` | Memory / learning |

## Architecture (fixed path)

- **Scalar / neuron / network / brain** — `*_fixed.zig`
- **Genetics** — 64-codon PRIMARY, ORF → expression → phenotype → W
- **Organism** — continuous tick + inject + modulation
- **Memory** — episodic fingerprints, 5W1H, curiosity
- **Machine language** — `machine_lang_fixed.zig` (native I/O tongue)
- **English codec** — `lexicon_en_fixed.zig` + `host_tts_fixed.zig`
- **Knowledge apply** — `grade_practice_fixed.zig` (facts ≠ word labels)
- **Live plant** — display, mic, TTS, optional formant speech organ
- **Attention / scene** — EEG-anchored gates, ambient scene analysis

IEEE f64 modules remain **lab / parity** only (`float-lab`, `sme-float`).

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

- `docs/ZIG_MIND_AUTHORITY.md`
- `docs/FIXED_POINT_EXPERIMENT.md`
- `docs/TRINARY_BARE_METAL.md`
- `docs/GENOME_AS_CODE.md`
- `docs/BARE_METAL_IO.md`
- `docs/SPEECH_ORGAN_DOCTRINE.md`
- `docs/BIO_SENSORY_SYSTEM.md`
- `docs/HOST_IO_ZIG.md`
- `docs/LANGUAGE_AND_SPEECH.md`

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

