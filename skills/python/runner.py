#!/usr/bin/env python3
"""FSOT skill organ runner — sandbox for procedural Python skills.

Not a second brain. Zig Fixed mind remains authority.
This process only executes a named skill module under skills/ and prints:

  RESULT: <text>

Usage:
  python runner.py <skill_name> [args...]

Safety (v0):
  - timeout enforced by parent Zig process
  - skills must live under skills/ next to this file
  - no network helpers imported by default in built-ins
  - skill name must be [a-z0-9_]+
"""
from __future__ import annotations

import importlib.util
import re
import sys
from pathlib import Path

SKILLS_ROOT = Path(__file__).resolve().parent / "skills"
NAME_RE = re.compile(r"^[a-z][a-z0-9_]{0,47}$")


def fail(msg: str, code: int = 1) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
    print(f"RESULT: ERROR {msg}")
    sys.exit(code)


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        fail("usage: runner.py <skill> [args...]")
    name = argv[1].strip().lower()
    if not NAME_RE.match(name):
        fail(f"invalid skill name: {name!r}")
    path = SKILLS_ROOT / f"{name}.py"
    if not path.is_file():
        fail(f"skill not found: {name}")
    # Load as module without putting parent on sys.path for arbitrary imports
    spec = importlib.util.spec_from_file_location(f"fsot_skill_{name}", path)
    if spec is None or spec.loader is None:
        fail(f"cannot load skill: {name}")
    mod = importlib.util.module_from_spec(spec)
    try:
        spec.loader.exec_module(mod)
    except Exception as e:  # noqa: BLE001 — surface skill errors to organ
        fail(f"skill import error: {e}")
    if not hasattr(mod, "run"):
        fail(f"skill {name} missing run(*args) -> str")
    args = argv[2:]
    try:
        out = mod.run(*args)
    except Exception as e:  # noqa: BLE001
        fail(f"skill runtime error: {e}")
    text = str(out).strip().replace("\n", " ").replace("\r", " ")
    if not text:
        fail("empty skill result")
    # Single RESULT line for Zig parser
    print(f"RESULT: {text[:400]}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
