"""Skill: mul — product of numbers."""


def run(*args: str) -> str:
    parts: list[str] = []
    for a in args:
        parts.extend(a.replace(",", " ").split())
    if not parts:
        return "1"
    total = 1.0
    for p in parts:
        total *= float(p)
    if total == int(total):
        return str(int(total))
    return str(total)
