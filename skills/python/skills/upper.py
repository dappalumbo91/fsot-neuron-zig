"""Skill: upper — uppercase text."""


def run(*args: str) -> str:
    return " ".join(args).upper() if args else ""
