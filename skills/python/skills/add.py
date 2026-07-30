"""Skill: add — sum numbers given as separate args or one space-separated string."""


def run(*args: str) -> str:
    parts: list[str] = []
    for a in args:
        parts.extend(a.replace(",", " ").split())
    if not parts:
        return "0"
    total = 0.0
    for p in parts:
        total += float(p)
    if total == int(total):
        return str(int(total))
    return str(total)
