"""Skill: hash_fnv — FNV-1a 32-bit hash of joined args (matches mind hash spirit)."""


def run(*args: str) -> str:
    s = " ".join(args).encode("utf-8")
    h = 2166136261
    for b in s:
        h ^= b
        h = (h * 16777619) & 0xFFFFFFFF
    if h == 0:
        h = 1
    return str(h)
