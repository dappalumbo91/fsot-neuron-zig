# Operating specs — where the FSOT genetic mind can run

**Repo:** fsot-neuron-zig  
**Doctrine:** same architecture on floor and growth host; capacity tiers change STM budgets, not the law.

---

## 1. Two run surfaces

| Surface | Binary | What it is |
|---------|--------|------------|
| **Host mind** | `zig-out/bin/fsot_mind.exe` (Windows) / `fsot_mind` | Full genetic Fixed mind: FI, Allen, think, speech, capacity |
| **QEMU kernel** | `zig-out/bin/fsot_trit_kernel` | Freestanding Multiboot x86: trit · codon · genotype · fixed · genetic brain lite |

```powershell
zig build                    # host mind → zig-out
zig build kernel             # freestanding kernel → zig-out
.\run_qemu.ps1               # build kernel + QEMU serial gate
.\zig-out\bin\fsot_mind.exe capacity
.\zig-out\bin\fsot_mind.exe genetic-var
.\zig-out\bin\fsot_mind.exe isi-ks      # full ISI distribution KS product
```

---

## 2. Minimum host (development floor)

| Item | Spec |
|------|------|
| **Class** | 2012–2018 Mac Mini **or** Pi 4/5 class **or** any ≥4–8 GB laptop |
| **CPU** | x86_64 or aarch64 |
| **RAM** | **≥ 4 GB** usable |
| **Storage** | Binary + `data/` (lexicon, optional LTM) — hundreds of MB class |
| **GPU** | **Not required** |
| **OS** | Windows (current lab), Linux/macOS host builds intended |

### Floor modes that must work

```text
fsot_mind capacity
fsot_mind genetic-var    # mutateOrf diversity under 64-codon law
fsot_mind isi-ks         # full ISI distribution KS vs Allen CSV (product)
fsot_mind bio-learn
fsot_mind speech
fsot_mind think          # short probe
fsot_mind fixed          # full bio stack — slower on 4GB but valid
```

### QEMU gate (when qemu-system-x86_64 installed) — **full Allen, not smoke**

```text
.\run_qemu.ps1
# or host parity twin:
.\zig-out\bin\fsot_mind.exe allen-bare
```

Requires genetic FI vs **full Allen targets** on the kernel:

- pop: ISI ≤1.42 ms, adapt abs, every cell 32/32  
- class: Pyr/PV/SST/VIP abs Hz + PV≫Pyr  
- lines: `FSOT_ALLEN_BAREMETAL_FULL PASS` · `FSOT_ALLEN_ON_QEMU_OK`

Budget: up to ~15 min under soft-FPU (`-m 256M`).

### Heavy (prefer desktop / workstation)

```text
fsot_mind think-hour
fsot_mind intel-loop / frontier
fsot_mind fixed          # includes allen-dist + genetic-var — multi-minute
fsot_mind gpu-organ
```

---

## 3. QEMU / bare-metal envelope

| Item | Spec |
|------|------|
| **Image** | Multiboot1, **32-bit x86**, freestanding |
| **QEMU** | `qemu-system-x86_64 -kernel fsot_trit_kernel` |
| **RAM flag** | **`-m 64M`** (script default) — kernel + soft-FPU headroom |
| **Display** | none (serial only) |
| **I/O** | COM1 serial log |
| **Time** | Genetic brain init under soft-FPU: allow **~90 s** on Windows QEMU |
| **Pass lines** | `FSOT_CODON PASS` · `FSOT_GENOTYPE PASS` · `FSOT_BRAIN PASS` · `FSOT_INTEL_BAREMETAL_OK` |

Kernel stack reserve: **256 KiB** (`main_kernel.zig`).  
Not a full OS — smoke of **trinary + codon + genetic brain dynamics**.

---

## 4. Measured artifact sizes (this lab, 2026-08-01)

| Artifact | Size |
|----------|-----:|
| `fsot_mind.exe` (ReleaseFast) | **2 904 576 B** (~2.8 MB) |
| `fsot_trit_kernel` (ReleaseSafe freestanding) | **1 031 216 B** (~1.0 MB) |

Rebuild when shipping; re-check `zig-out/bin/`.

---

## 5. Capacity tiers (runtime)

| Tier | RAM | Role |
|------|-----|------|
| **min** | &lt;12 GB | Floor STM (lit 40, grown 256) + disk LTM |
| **desktop** | ≥12 GB | Medium STM |
| **workstation** | ≥24 GB | Fat STM (lab Omen 32 GB) |

```text
fsot_mind capacity
```

Reports tier, RAM probe, GPU organ flag, STM budgets, LTM paths.

---

## 6. What can *operate* this mind

| Platform | Host mind | QEMU kernel | Notes |
|----------|:---------:|:-----------:|-------|
| Windows x64 lab (Omen) | **Yes** | **Yes** | Primary build |
| Linux x64 | **Yes** (rebuild) | **Yes** | same zig target |
| macOS aarch64 / x64 | **Yes** (rebuild) | **Yes** (QEMU) | Mini as target body |
| Pi 4/5 4–8 GB | **Yes** (floor modes) | via QEMU/host | no GPU required |
| 64 MB bare Multiboot | — | **kernel only** | lite genetic smoke |

---

## 7. Related

- [`MINIMUM_STACK.md`](MINIMUM_STACK.md) — developmental floor  
- [`SILICON_BODY_ARCHITECTURE.md`](SILICON_BODY_ARCHITECTURE.md)  
- [`GENETICS_CODE_AUDIT.md`](GENETICS_CODE_AUDIT.md)  
- [`ARCHIVE_SOLVED_MATH_FOR_MIND.md`](ARCHIVE_SOLVED_MATH_FOR_MIND.md)  
