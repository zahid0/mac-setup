#!/bin/bash
# status.sh — Check the status of a background process
# Usage: ./scripts/status.sh <session-name>
#
# Output:
#   RUNNING    — The command is still executing
#   EXITED <N> — The command finished with exit code N
#   NOT_FOUND  — No window with that name exists

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <session-name>" >&2
  exit 1
fi

SESSION_NAME="$1"
TMUX_SESSION="background-tasks"
WINDOW="bgr-${SESSION_NAME}"

if ! tmux has-session -t "$TMUX_SESSION" 2>/dev/null ||
   ! tmux list-windows -t "$TMUX_SESSION" -F '#{window_name}' 2>/dev/null | grep -qx "$WINDOW"; then
  echo "NOT_FOUND"
  exit 0
fi

# Capture the full pane output
CAPTURE=$(tmux capture-pane -t "$TMUX_SESSION:$WINDOW" -p -S - 2>/dev/null || true)

# Look for the last occurrence of [BGR_EXIT:<code>]
# Use || true to avoid pipefail issues when grep finds no match
EXIT_LINE=$(echo "$CAPTURE" | grep -o '\[BGR_EXIT:[0-9][0-9]*\]' | tail -1 || true)

if [ -n "$EXIT_LINE" ]; then
  # Extract the exit code
  CODE=$(echo "$EXIT_LINE" | grep -o '[0-9][0-9]*')
  echo "EXITED $CODE"
else
  echo "RUNNING"
fi
