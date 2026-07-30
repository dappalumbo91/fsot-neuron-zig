"""Skill: div — a / b (two numbers)."""


def run(*args: str) -> str:
    parts: list[str] = []
    for a in args:
        parts.extend(a.replace(",", " ").split())
    if len(parts) < 2:
        raise ValueError("div needs two numbers")
    a, b = float(parts[0]), float(parts[1])
    if b == 0:
        raise ValueError("division by zero")
    r = a / b
    if r == int(r):
        return str(int(r))
    return str(r)
