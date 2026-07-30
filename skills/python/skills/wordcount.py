"""Skill: wordcount — count whitespace-separated tokens."""


def run(*args: str) -> str:
    s = " ".join(args) if args else ""
    n = len(s.split()) if s.strip() else 0
    return str(n)
