# Agent Instructions

## Git Policy
- Do NOT commit changes to git unless explicitly asked to do so by the user.
- Never stage, commit, or push changes without the user's explicit request.
- If you need to make changes, just modify the files. Leave version control decisions to the user.

## Skill References
- Skill reference files (e.g., `performance-checklist.md`, `security-checklist.md`) live in `~/.agents/references/`, NOT inside the skill directory itself.
- When a skill's SKILL.md says "see `references/foo.md`", resolve it against `~/.agents/references/foo.md`.

## UV Path
- The uv executable is located at `/Users/zahid/.venv/bin/uv`.

## Python Formatting (after every change)
Format and lint any Python file you create or modify, targeting it by explicit path — never recursively over a tree.

```bash
black <files>
ruff check <files> --fix --select E,F,I,UP,W --ignore E203,E501
```

If either tool is missing from PATH and `$HOME/.local/bin`, install it non-interactively (`uv tool install` preferred, else `python -m pip install --user`) without prompting. Report install failures and any lint issues `--fix` cannot resolve.

## Python annotations
Do not add `from __future__ import annotations`. Python 3.14's default deferred evaluation (PEP 649) already handles forward references and lazy evaluation natively — this import is legacy and forces the older PEP 563 string-based behavior instead.
