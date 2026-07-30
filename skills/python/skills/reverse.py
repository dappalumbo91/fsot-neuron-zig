"""Skill: reverse — reverse a string argument."""


def run(*args: str) -> str:
    s = " ".join(args) if args else ""
    return s[::-1]
