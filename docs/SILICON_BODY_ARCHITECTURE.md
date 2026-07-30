# Silicon body architecture — OS-as-brain on PC substrate

**Repo:** fsot-neuron-zig  
**Doctrine date:** 2026-07-30  

Silicon is the **body**. The OS stack is the **anatomy**. FSOT + genetics is the **physiology**.  
We are not limited to “one small CPU loop forever” — we use **CPU + RAM + GPU + disk + network** as organs, under one Fixed mind authority.

---

## Body inventory (this development host)

| Role | Hardware (current lab) |
|------|-------------------------|
| **Growth host** | HP Omen 35L · **32 GB RAM** · modern AMD CPU · **RTX 5070** |
| **Target body (flash later)** | Mac Mini (image after QEMU validation) |
| **Simulation path** | QEMU freestanding Multiboot kernel on the Omen (`run_qemu.ps1`) |

Plenty of room to grow **above** the minimum stack. Minimum stack is the **developmental floor**, not the ceiling.

---

## OS stack = brain anatomy

```text
┌─────────────────────────────────────────────────────────┐
│  Shell / embodiment     speech · logs · TUI · later I/O  │  ← behavior surface
├─────────────────────────────────────────────────────────┤
│  Userspace habits       think · know-query · school      │  ← skills / learning
├─────────────────────────────────────────────────────────┤
│  Organ processes        GPU workers · disk page · APIs   │  ← body organs
├─────────────────────────────────────────────────────────┤
│  Kernel mind            Fixed lattice · STDP · neuromod  │  ← FSOT physiology
├─────────────────────────────────────────────────────────┤
│  BIOS / boot            identity · serial · QEMU/image   │  ← always boots
└─────────────────────────────────────────────────────────┘
```

| OS layer | Brain analogue | FSOT role |
|----------|----------------|-----------|
| BIOS / firmware | Brainstem / life support | Boot, serial, hard safety |
| Kernel | Core networks | Genetic Fixed step, claimability |
| Drivers / organs | Sensory-motor organs | Host senses, TTS, GPU batch, disk LTM, wet encode |
| Userspace | Habits / cognition | bio-learn, think-hour, know-query |
| Shell | Behavior | Speech, logs, pending questions |

**GPU is an organ**, not a second mind. PyTorch-style side brains must not outvote Fixed authority.

### Think-path organs (current)

| Organ | Substrate | Role |
|-------|-----------|------|
| **Wet encode** | **CPU Fixed** lattice | neuromod→step→glia→mol.tagCoactive→STDP→consol→prune on every `studyFact` |
| **STM** | RAM | grown bank + episodic ring + speak engrams |
| **LTM** | disk `data/ltm/` | spill when STM full; warm re-encode into hot set |
| **Deep sleep VRAM** | GPU / FSOT-GPU consensus | every 4th NREM: matrix offload + top-K replay |
| **Skill organ** | Python interpreter | procedural tools (`skills/python/`) |

Wet channel Markov is intentionally CPU-bound Fixed physiology. GPU is for cortex-scale consensus, not spine ODEs.

---

## Minimum stack (developmental floor)

See **`MINIMUM_STACK.md`**.

Anything that **must** run on the floor (Mac Mini class / Pi class / QEMU soft body) defines the **soul**.  
Omen 32 GB + 5070 is **capacity growth** for more episodes, engrams, literature cards, parallel organs.

---

## Capacity tiers (scaling options)

| Tier | Anchor | Intent |
|------|--------|--------|
| `min` | ~8 GB class (Mac Mini / Pi-class) | Always green; small pools |
| `desktop` | ~16 GB | Comfortable school + think |
| `workstation` | **32 GB Omen-class** | Full lit boot + long think |
| `gpu_organ` | CUDA/Vulkan present | Future parallel sleep/vision (flag only until wired) |

Runtime probe: `fsot_mind capacity` → RAM, tier, recommended pool sizes.

---

## Biological accuracy (non-negotiable)

Scaling **does not** mean free-parameter nets or LLM context stuffing.

| Biology | Silicon body |
|---------|----------------|
| Plasticity | STDP / neuromod / re-encode |
| Limited neurogenesis | Grow `n_active` ≤ N_MAX under policy |
| Working memory (STM) | Hot pools in **RAM** (grown bank, episodes, engrams) |
| Hippocampus → cortex (LTM) | Full STM → **disk spill** under `data/ltm/` (unbounded growth) |
| Parallel / serial thought | **CPU** (+ **GPU organ** later) — compute, not knowledge caps |
| Sensory organs | Mic, display, GPU vision later |
| Library / tools | know-query, archive APIs, arxiv/wiki |
| Sleep | Quiet + NREM ticks; GPU replay later |

### STM vs LTM (non-negotiable)

- Compile-time `MAX_*` and tier `grown_cap` are **STM hot windows**, not knowledge ceilings.
- When STM is full the mind **pages cold items to disk LTM** and keeps learning.
- A think run must **never** stop solely because “memory is full.”
- LTM paths: `data/ltm/grown.jsonl`, `engrams.jsonl`, `episodes.jsonl`.

Responses stay: **retrieve · ground · articulate · self-correct · pending if unknown**.

---

## Growth path (order)

1. **Minimum stack green** on QEMU + host mind modes  
2. **Tiered STM pools** on Omen (`capacity_tier_fixed` — hot windows only)  
3. **Disk LTM** — spill grown / engrams / episodes (`ltm_disk_fixed`) — **shipped**  
4. **Multi-engram articulation** (depth of speech)  
5. **LTM retrieve** into STM on demand — `passLtmWarm` / `ltm_disk_fixed`  
6. **GPU organ** — bridge to **[FSOT-GPU](https://github.com/dappalumbo91/FSOT-GPU)** (trinary pack, consensus, native CUDA); see [`FSOT_GPU_ORGAN.md`](FSOT_GPU_ORGAN.md)  
7. **Python skill organ** — interpreter sandbox under Fixed mind (`skills/python/`)  
8. **Flash image → Mac Mini** as dedicated body  

---

## Related

- [`MINIMUM_STACK.md`](MINIMUM_STACK.md)  
- [`ZIG_MIND_AUTHORITY.md`](ZIG_MIND_AUTHORITY.md)  
- [`BARE_METAL_IO.md`](BARE_METAL_IO.md) · QEMU serial  
- [`KNOW_QUERY_TOOL.md`](KNOW_QUERY_TOOL.md) · tool organs  
