"""Skill: fsot_quantum_organ — readout of the FSOT-Quantum law organ.

Not mind authority. Reads data/organs/fsot_quantum_organ.json
(or FSOT_QUANTUM_ORGAN path). No network. No LLM.

Usage (via runner):
  pin
  S Quantum_Mechanics
  kappa Quantum_Computing Psychology
  qi CHSH_TSIRELSON
  look
"""

from __future__ import annotations

import json
import os
from pathlib import Path


def _load() -> dict:
    env = os.environ.get("FSOT_QUANTUM_ORGAN", "").strip()
    cands = []
    if env:
        cands.append(Path(env))
    # neuron-zig repo: skills/python/skills/this.py → repo data/organs/
    here = Path(__file__).resolve()
    cands.append(here.parents[3] / "data" / "organs" / "fsot_quantum_organ.json")
    qroot = os.environ.get("FSOT_QUANTUM_ROOT", "").strip()
    if qroot:
        cands.append(Path(qroot) / "results" / "organ_export.json")
    for p in cands:
        if p.is_file():
            return json.loads(p.read_text(encoding="utf-8"))
    raise FileNotFoundError(
        "organ JSON missing — run `python -m fsot_quantum organ` and copy to data/organs/"
    )


def run(*args: str) -> str:
    blob = _load()
    if not args or args[0] in ("pin", "help"):
        return f"pin={blob.get('pin')} ok={blob.get('pin_ok')} C_factor={blob.get('C_factor')}"
    cmd = args[0]
    if cmd == "S" and len(args) >= 2:
        name = args[1]
        s = (blob.get("S") or {}).get(name)
        if s is None:
            return f"ERROR unknown domain {name}"
        return f"{name} {s}"
    if cmd == "kappa" and len(args) >= 3:
        a, b = args[1], args[2]
        for e in blob.get("bleed") or []:
            if {e.get("from"), e.get("to")} == {a, b}:
                return f"kappa {a} {b} {e.get('kappa')}"
        return f"ERROR no bleed {a} {b}"
    if cmd == "qi":
        qid = args[1] if len(args) > 1 else "CHSH_TSIRELSON"
        for q in blob.get("qi") or []:
            if q.get("id") == qid:
                return f"{q['id']} {q['answer']}"
        return f"ERROR unknown qi {qid}"
    if cmd == "look":
        return " ".join(blob.get("look_path") or [])
    return "ERROR usage: pin | S <Domain> | kappa <A> <B> | qi [ID] | look"
