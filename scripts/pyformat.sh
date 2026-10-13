#!/usr/bin/env bash
#
# pyformat - format and lint Python files with black + ruff.
# Manual tool: operates recursively over the given tree (default: cwd).
#
set -euo pipefail

# Tool locations that are not necessarily on PATH.
EXTRA_BINS=("$HOME/.local/bin" "/Users/zahid/.venv/bin")
for d in "${EXTRA_BINS[@]}"; do
    [ -d "$d" ] && PATH="$d:$PATH"
done
export PATH

SELECT="E,F,I,UP,W"
# W503 is not implemented by ruff and would abort the run.
IGNORE="E203,E501"
EXCLUDES="(\.git|__pycache__|\.venv|venv|node_modules|site-packages|\.tox|\.eggs|build|dist)"

# Targets: explicit paths if given, else the current tree.
TARGETS=("$@")
[ ${#TARGETS[@]} -eq 0 ] && TARGETS=(".")

missing=()
for tool in black ruff; do
    command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
done

if [ ${#missing[@]} -gt 0 ]; then
    echo "Installing missing tools: ${missing[*]}" >&2
    if command -v uv >/dev/null 2>&1; then
        uv tool install "${missing[@]}"
    else
        python3 -m pip install --user --upgrade "${missing[@]}"
    fi
    PATH="$HOME/.local/bin:$PATH"
    export PATH
    for tool in "${missing[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            echo "pyformat: failed to install '$tool'" >&2
            exit 1
        fi
    done
fi

# 1. ruff autofixes: sort imports (I), drop unused (F), modernize (UP).
# Exit 1 means "issues found/remaining" (normal); >=2 is a real error and fatal.
set +e
ruff check "${TARGETS[@]}" \
    --fix \
    --select "$SELECT" \
    --ignore "$IGNORE" \
    --extend-exclude "$EXCLUDES"
status=$?
set -e
if [ "$status" -ge 2 ]; then
    echo "pyformat: ruff failed (exit $status)" >&2
    exit "$status"
fi

# 2. black is the formatter of record; run last so its style wins.
black "${TARGETS[@]}" --extend-exclude "$EXCLUDES"

# 3. Report anything ruff could not fix automatically.
ruff check "${TARGETS[@]}" \
    --select "$SELECT" \
    --ignore "$IGNORE" \
    --extend-exclude "$EXCLUDES"
