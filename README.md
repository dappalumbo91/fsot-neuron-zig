# FSOT Neuron Zig

**Fluid Spacetime Omni-Theory (FSOT) neural mind — Zig authority.**

Bare-metal multi-region brain, 64-codon genetic spine, fixed-point lattice (SCALE=1e12), episodic 5W1H memory, curiosity, transfer, teach, modulate, SME bands, short-horizon learning, vision inject, and tutor-ablated pixel-id.

Python is **optional host I/O only** (media decode / lab reports). The mind core runs in Zig without Python.

| | |
|--|--|
| **Theory** | Fluid Spacetime Omni-Theory (FSOT) 2.1 |
| **Authority** | Fixed-point lattice (`src/fixed.zig`) |
| **Language** | Zig 0.15+ |
| **Related monorepo** | [FSOT-2.1-Neural](https://github.com/dappalumbo91/FSOT-2.1-Neural) |

## Quick start

```bash
# Zig 0.15+ on PATH
zig build -Doptimize=ReleaseFast

# Mind host (fixed authority suite)
./zig-out/bin/fsot_mind all

# Useful modes
./zig-out/bin/fsot_mind fixed
./zig-out/bin/fsot_mind teach
./zig-out/bin/fsot_mind transfer
./zig-out/bin/fsot_mind short-horizon
./zig-out/bin/fsot_mind sme
./zig-out/bin/fsot_mind pixel-id
./zig-out/bin/fsot_mind stress
```

Windows (AV sometimes locks `zig-out`):

```powershell
$out = Join-Path $env:TEMP "fsot_mind.exe"
zig build-exe -OReleaseFast -femit-bin=$out --name fsot_mind src/main_mind.zig
& $out short-horizon
```

## Architecture (fixed path)

- **Scalar / neuron / network / brain** — `*_fixed.zig`
- **Genetics** — full 64-codon PRIMARY, ORF → expression → phenotype → W
- **Organism** — continuous tick + inject + self-modulation (POOF/SUCTION)
- **Memory** — episodic fingerprints, 5W1H slots, curiosity fill
- **Learning** — encode/retrieve, curriculum, short-horizon, transfer (no title cheats)
- **Vision inject** — host text feature frames → Fixed bus
- **SME** — theta/gamma band proxies on Fixed (encode vs rest)

IEEE f64 modules remain as **lab / parity** only (`float-lab`, `sme-float`).

## Doctrine docs (repo only)

- `docs/ZIG_MIND_AUTHORITY.md`
- `docs/FIXED_POINT_EXPERIMENT.md`
- `docs/TRINARY_BARE_METAL.md`
- `docs/GENOME_AS_CODE.md`
- `docs/BARE_METAL_IO.md`

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

## Language learning

See monorepo docs/LANGUAGE_LEARNING_METHODOLOGY.md for the reproducible lexicon + PK/K/G1 pipeline (machine language student; Ollama teacher optional).

