# Archive ↔ Zig mind — biological accuracy cross-reference

**Purpose:** Silicon-neuron substrate under the **same FSOT law** that routes cosmology and other domains. Be as wet-lab accurate as the archive already proved; feed Zig refinements back into the archive.

| Authority | Role |
|-----------|------|
| **I:\FSOT-Physical-Archive** | Offline master: scalar, pin D1D38A, multi-prover, public-data panels |
| **[FSOT-2.1-Lean](https://github.com/dappalumbo91/FSOT-2.1-Lean)** | **GitHub face of the Physical Archive** — Lean + verification bundle |
| **[FSOT-2.1-Neural](https://github.com/dappalumbo91/FSOT-2.1-Neural)** / `I:\fsot nuron` | Allen ephys, wetlab 37/37, calibrate/scalpel, Python battery |
| **This repo** / `I:\fsot-neuron-zig` | Fixed lattice **neural fold** domain engine: genetics, wet cascade, think/sleep/LTM/GPU |

**Unity claim:** Cosmology fold and neural fold share \(S=K(T_1+T_2+T_3)\) (pin D1D38A). Zig is embodiment + domain metrics, not a second theory.  
Full map: [`ARCHIVE_PIN_AND_MIND_FOLD.md`](ARCHIVE_PIN_AND_MIND_FOLD.md) · archive `ZIG_MIND_AND_GITHUB_MAP.md`

**Silicon vision:** process-accurate neuron/network laws on non-biological substrate (code → chip). Not a claim of molecular identity with wet tissue.

---

## Master matrix

| Capability | Archive / monorepo | Zig mind | Accuracy status | Action |
|------------|-------------------|----------|-----------------|--------|
| **FSOT scalar zero free params** | `fsot_bridge`, pin D1D38A | `fixed.zig` SCALE=1e12 | **Parity** | Keep both |
| **64-codon trinary map** | wetlab T0, chemical_codon | `codon_fixed` | **Parity** | Keep both |
| **Gene ORFs SCN/KCN/CACNA/LEAK** | wetlab T4 | `genotype_fixed` | **Parity** | Keep both |
| **Genetic W pair law** | genetic_network | `genetic_fixed.fsotPairWeight` | **Parity** | Keep both |
| **Cell types Pyr/PV/SST/VIP fractions** | cell_types | `cell_types.zig` | **Parity** | Keep both |
| **Allen pop ISI bio_match ≤2%** | calibrate + report_card **closed ~1.26%** | `runAllenBioMatch` **closed ~0.77%** | **Zig ≥ archive** | Zig → archive note |
| **Allen pop adapt ≤10% gate / ≤2.5% iron** | archive Python residual **~6.7%** | Zig dual-polish **~1.6%** iron | **Zig ≥ archive** | Keep |
| **Class rates Pyr/PV/SST/VIP ≤2%** | wetlab T2 **closed** | `scalpel_rate_fixed` **ported** | **Closing** | Zig gate |
| **PV ≫ Pyr order** | wetlab critical | scalpel `pv_faster_than_pyr` | **Ported** | Keep |
| **bio_match vs efficient modes** | `modes.py` | pop ISI lock = bio_match; efficient not default for mind | **Partial** | optional efficient later |
| **STDP** | learning paths | `stdp_fixed` + think `wet_encode` | **Wired into studyFact** | Keep |
| **Glia process** | limited in Python | `glia_fixed` + wet encode/sleep | **Zig ahead (think-coupled)** | → archive note |
| **Molecular cascade** | limited | `molecular_fixed` + wet encode | **Zig ahead (think-coupled)** | → archive note |
| **Neuromod 4 species + sleep** | self_modulation / studies | `neuromod_fixed` + think sleep | **Zig mind-coupled** | mut≠0 via wet W change |
| **Sleep replay + consolidate** | consolidate_study | sleep_replay + VRAM batch | **Both** | Keep |
| **SME theta/gamma** | learning_eeg_study | `eeg_gate_anchors_fixed` | **Parity direction** | Keep |
| **Channel stoch AMPA/NMDA** | wet_stack Lean + Python | `channel_stoch_fixed` | **Zig module; not in think tick** | Wire or gate-only |
| **Failure / wire-around** | failure_boundaries | failure_fixed / wire_around | **Parity** | Keep |
| **GPU consensus** | FSOT-GPU + gpu_consensus | gpu_organ + VRAM offload | **Bridged** | Keep |
| **Wetlab battery 37/37** | run_wetlab_accuracy_battery | certificate in data/results | **Archive measured** | Zig gates subset |
| **Think LTM STM disk** | — | ltm_disk_fixed | **Zig ahead** | → archive |
| **Python skill organ** | — | skill_organ_fixed | **Zig body organ** | optional archive |

---

## Gaps (priority)

### A. Archive → Zig (must not be less accurate)

1. ~~Allen pop ISI residual~~ — **done** (`FSOT_ALLEN_ISI_RESIDUAL_CLOSED`)  
2. ~~Class-rate scalpel~~ — **ported** (`scalpel_rate_fixed`, wetlab T2 numbers)  
3. ~~Wire wet cascade into organism encode path~~ — **done** (`wet_encode_fixed` → `studyFact` / sleep; full neuromod→step→glia→mol→STDP→consol→prune; CPU Fixed lattice; `mut≥1` after boot study)  
4. **efficient mode** for compute-friendly ISI when not validating  

### B. Zig → Archive (feed forward)

1. Document Allen lock port results in monorepo artifacts  
2. LTM disk + VRAM sleep batch as body organs  
3. Concept-level think composition + bio metrics JSONL  

---

## Allen numbers (shared authority)

| Quantity | Value | Source |
|----------|------:|--------|
| Pop ISI target (bio_match) | 70.5986 ms | bio_report_card.json |
| Pop adapt target | 0.05115 | bio_report_card.json |
| ISI tol | **2%** | wetlab doctrine |
| Pyr rate | 16.351 Hz | wetlab T1 Cre |
| PV rate | 83.350 Hz | wetlab T1 Cre |
| SST rate | 29.538 Hz | wetlab T1 Cre |
| VIP rate | 34.815 Hz | wetlab T1 Cre |
| Class rate tol | **2%** | wetlab T2 |

---

## How to re-verify

```powershell
# Zig mind
cd I:\fsot-neuron-zig
zig build -Doptimize=ReleaseFast
.\zig-out\bin\fsot_mind.exe fixed      # Allen lock + structure
.\zig-out\bin\fsot_mind.exe scalpel    # class rates ≤2%

# Archive monorepo (when env set)
cd "I:\fsot nuron"
$env:FSOT_PHYSICAL_ARCHIVE = "I:\FSOT-Physical-Archive"
python run_wetlab_accuracy_battery.py
python run_bio_validate.py
```

---

## Silicon-neuron honesty

| Claim | Allowed |
|-------|---------|
| Process-accurate FI / ISI / adapt / class rates vs public Allen | **Yes** (within tol) |
| Genetic code → phenotype → W on Fixed lattice | **Yes** |
| Molecular identity with wet neurons | **No** |
| Chip / molecular silicon tissue | **Future path**, not current claim |

Update this file whenever either side closes a gap.
