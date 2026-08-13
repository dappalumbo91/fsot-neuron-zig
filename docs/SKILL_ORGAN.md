# Python skill organ

**Doctrine:** Fixed Zig mind = authority. Python = **procedural organ** (hands + tools), not a second brain / LLM.

```text
fsot_mind skill
fsot_mind skill-run add "2 3"
fsot_mind skill-run gpu_topk "3 2 | 1 0 | 0 1 | 1 0.1"
```

## Layout

```
skills/python/
  runner.py           # sandbox entry: RESULT: <text>
  skills/
    add.py mul.py div.py gcd.py
    reverse.py upper.py sort_words.py wordcount.py hash_fnv.py
    read_text.py      # sandboxed: skills/ and data/ only
    gpu_topk.py       # optional torch-CUDA matrix top pair
    fsot_quantum_organ.py  # law organ readout (S, κ, QI) — not a second mind
```

## Contract

Each skill exports:

```python
def run(*args: str) -> str:
    ...
```

Runner prints one line:

```text
RESULT: <single-line text>
```

Zig `skill_organ_fixed` spawns Python with timeout, parses `RESULT:`, and can `bindSkillResult` into SpeakEngram / episodes (experience learning).

## Safety (v0)

- Skill names: `[a-z][a-z0-9_]*` only  
- Parent timeout (default 8s)  
- `read_text` rejects `..`, absolute paths, anything outside `skills/` / `data/`  
- No network helpers in built-ins  
- Mind may call skills rarely during think (`skill_every` on workstation)

## Later

- Rust compiled skills behind the same organ interface  
- Skill discovery from engrams / pending questions  
