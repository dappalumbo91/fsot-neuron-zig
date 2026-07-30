"""Skill: gcd — greatest common divisor of integers."""

import math


def run(*args: str) -> str:
    parts: list[str] = []
    for a in args:
        parts.extend(a.replace(",", " ").split())
    if not parts:
        return "0"
    nums = [int(float(p)) for p in parts]
    g = abs(nums[0])
    for n in nums[1:]:
        g = math.gcd(g, abs(n))
    return str(g)
