# FSOT-Quantum organ — law readout, not a second mind

**Doctrine:** Zig Fixed lattice remains mind authority.  
[FSOT-Quantum](https://github.com/dappalumbo91/FSOT-Quantum) is a **GPU/law organ**: domain \(S\), bleed \(\kappa\), pin QI.

Architecture this organ implements: [`FSOT_NATIVE_MIND_FROM_QUANTUM_FOLD.md`](FSOT_NATIVE_MIND_FROM_QUANTUM_FOLD.md).

## Snapshot

`data/organs/fsot_quantum_organ.json` is a frozen readout (pin D1D38A).

Regenerate from the quantum repo (does not change this kernel):

```powershell
cd <FSOT-Quantum>
$env:PYTHONPATH = (Get-Location).Path
python -m fsot_quantum organ
copy results\organ_export.json <this-repo>\data\organs\fsot_quantum_organ.json
```

## Skill

```text
fsot_mind skill-run fsot_quantum_organ pin
fsot_mind skill-run fsot_quantum_organ "S Quantum_Mechanics"
fsot_mind skill-run fsot_quantum_organ "kappa Quantum_Computing Psychology"
fsot_mind skill-run fsot_quantum_organ "qi CHSH_TSIRELSON"
fsot_mind skill-run fsot_quantum_organ look
```

Or:

```powershell
python skills\python\runner.py fsot_quantum_organ pin
```

No network. No LLM. If the JSON is missing, the skill errors; the mind stays honest.

## What the organ is allowed to answer

| Query | Meaning |
|-------|---------|
| `S <Domain>` | Pin scalar \(S=K(T_1+T_2+T_3)\) |
| `kappa A B` | Seed bleed on the mind/look path |
| `qi CHSH_TSIRELSON` | Tsirelson bound from seeds |
| `look` | QC dark → QO look → QM |

It does **not** vote on speak, compose, or claimability.

## Quantum wrap (same pin, later rungs)

The organ JSON is a law readout. The quantum fold’s living wrap is
[FSOT-Quantum `docs/STATUS.md`](https://github.com/dappalumbo91/FSOT-Quantum/blob/main/docs/STATUS.md):

- stale-target audit **20/20 @ 0.5%** vs YR4/PDG (three earlier misses were wrong objects, not a retune)
- leftover hired physics **41/41** + 212/212 Lean
- Gset family **10/11 under 1%** (G17 1.017% written, not crawled; champions still unmatched)
- exclusive \(B\to D\ell\nu\) **0.15%**; \(H_0\) Planck **0.024%** / SH0ES **1.00%** (Lean BH→WH)
- pin **D1D38A** not edited

Regenerate the JSON after a quantum wrap if the skill should carry the new `wrap` field.
