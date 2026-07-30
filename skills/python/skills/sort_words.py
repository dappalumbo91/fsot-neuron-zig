"""Skill: sort_words — sort whitespace-separated tokens alphabetically."""


def run(*args: str) -> str:
    parts: list[str] = []
    for a in args:
        parts.extend(a.split())
    parts.sort(key=str.lower)
    return " ".join(parts)
