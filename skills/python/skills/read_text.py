"""Skill: read_text — sandboxed read of a small text file under allowed roots.

Args: <relative_path> [max_chars]
Allowed roots: skills/, data/ (relative to repo cwd when mind launches runner).
"""

from pathlib import Path

ALLOWED_PREFIXES = ("skills/", "skills\\", "data/", "data\\")


def run(*args: str) -> str:
    if not args:
        raise ValueError("read_text needs a relative path under skills/ or data/")
    rel = args[0].strip().replace("\\", "/")
    # reject absolute and traversal
    if rel.startswith("/") or ":" in rel or ".." in rel.split("/"):
        raise ValueError("path not allowed")
    if not any(rel.startswith(p.replace("\\", "/")) or rel.startswith(p) for p in ("skills/", "data/")):
        # also allow bare skills/python/... style
        if not (rel.startswith("skills") or rel.startswith("data")):
            raise ValueError("only skills/ or data/ paths allowed")
    max_chars = 400
    if len(args) >= 2:
        max_chars = max(16, min(2000, int(args[1])))
    path = Path(rel)
    if not path.is_file():
        raise ValueError(f"file not found: {rel}")
    text = path.read_text(encoding="utf-8", errors="replace")
    text = text.replace("\n", " ").replace("\r", " ").strip()
    return text[:max_chars]
