# How to start the minds (Windows desktop)

## Double-click on Desktop

| Shortcut | What it opens |
|----------|----------------|
| **FSOT Mind Python.cmd** | Interactive menu (stays open) |
| **FSOT Mind Zig.cmd** | Zig authority menu |
| **FSOT Mind Haskell.cmd** | Haskell twin menu |
| **FSOT Mind Idris.cmd** | Idris twin (via WSL) |

Or open each project folder and double-click **`BOOT_MIND.cmd`** (Zig: **`BOOT_MENU.cmd`**).

## Why Python “crashed” before

Double-click ran `python run_mind.py` with **no arguments**. The program printed usage and **exited with code 2**, so the window closed immediately. That is fixed: no-args now opens a **menu** and waits for Enter.

## Requirements

| Twin | Needs |
|------|--------|
| Python | Python 3 on PATH |
| Zig | `zig` on PATH first build; then `zig-out\bin\fsot_mind.exe` |
| Haskell | `bin\fsot-mind.exe` (auto-built by BOOT if cabal available) |
| Idris | WSL2 + Idris2 / pack (`~/.local/bin`) |

## CLI (no menu)

```text
python run_mind.py phase-b
I:\fsot-neuron-zig\zig-out\bin\fsot_mind.exe glia-ca
bin\fsot-mind.exe phase-a
wsl ... ./build/exec/fsot-mind self-talk
```
