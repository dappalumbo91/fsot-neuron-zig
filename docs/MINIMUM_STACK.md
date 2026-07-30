# Minimum stack — developmental floor

**Purpose:** Define the **smallest body** that still *is* the FSOT mind.  
Everything above is **capacity growth**, not a different architecture.

---

## Floor (must always work)

| Item | Spec |
|------|------|
| **Class** | 2012–2018 Mac Mini class **or** current Raspberry Pi 4/5 class (**≥ 4–8 GB RAM**) |
| **CPU** | x86_64 or aarch64 host; freestanding x86 Multiboot for QEMU kernel path |
| **RAM** | **≥ 4 GB** usable for host mind; kernel path is tiny |
| **Storage** | Enough for binary + `data/` lexicon + optional lit paths |
| **GPU** | **Not required** |
| **Network** | Optional (know-query-live / Wikipedia) |

### Modes that must pass on the floor

```text
fsot_mind bio-learn
fsot_mind know-query          # local sources only
fsot_mind think               # probe (smaller lit card count)
fsot_mind speech / practice
# QEMU: run_qemu.ps1 when available
```

### Floor pool budgets — **STM hot windows only** (not knowledge ceilings)

| Pool | Floor STM | Workstation STM (Omen 32 GB) | Beyond STM |
|------|----------:|-----------------------------:|------------|
| Literature cards at think boot | 40 | 160 | (session load) |
| Grown concept bank | 256 | 1536 | **disk LTM spill** |
| Discover attempts / cycle | 1 | 2 | — |
| Episode store | 384 ring | 384 ring | **disk LTM spill** |
| Speak engrams | 512 | 512 | **disk LTM spill** |

**Doctrine:** RAM = short-term / working set. Disk (`data/ltm/`) = long-term.  
CPU (+ GPU later) = thought processes. **No hard-coded knowledge ceiling** — full STM → page cold → keep growing.  
Compile-time arrays bound the STM window for stack safety; growth continues on disk.

---

## Growth host (this lab)

| Item | Spec |
|------|------|
| **Machine** | HP Omen 35L |
| **RAM** | 32 GB |
| **CPU** | Modern AMD |
| **GPU** | RTX 5070 (organ flag; not mind authority) |
| **Role** | Develop, long think-hour, lit ingest, QEMU simulate, build flash image |

---

## Target body (next flash)

| Item | Spec |
|------|------|
| **Machine** | Mac Mini |
| **Path** | Validate on Omen host + QEMU → produce bootable image → flash Mini as dedicated body |
| **Goal** | Same kernel mind; capacity may be `min` or `desktop` tier depending on Mini RAM |

---

## Detection

```text
fsot_mind capacity
```

Reports RAM (when host APIs available), selected tier, and recommended think/lit budgets.

---

## Non-goals on the floor

- Requiring CUDA  
- Requiring 32 GB  
- LLM weights  
- Network for core PASS  

---

## See also

[`SILICON_BODY_ARCHITECTURE.md`](SILICON_BODY_ARCHITECTURE.md)  
