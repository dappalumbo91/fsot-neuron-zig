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

### Floor pool budgets (runtime soft + compile max)

| Pool | Floor | Workstation (Omen 32 GB) |
|------|------:|-------------------------:|
| Literature cards at think boot | 40 | 160 |
| Grown concept bank | 64 | 256 |
| Discover attempts / cycle | 1 | 2 |
| Episode store (compile max) | 192 ring | 192 ring (page later) |
| Speak engrams (compile max) | 160 | 160 |

Compile-time arrays stay at max; **runtime tier caps** how hard we fill them on small bodies.

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
