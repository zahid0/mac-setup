#!/bin/bash
# output.sh — View output from a background tmux window
# Usage: ./scripts/output.sh <session-name> [options]
#
# Options:
#   -t         Tail: show only the last lines (like tail -20)
#   -n <N>     Show last N lines (default: all)
#   -c         Clear the output buffer after reading

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <session-name> [-t] [-n <N>] [-c]" >&2
  exit 1
fi

SESSION_NAME="$1"
shift
TMUX_SESSION="background-tasks"
WINDOW="bgr-${SESSION_NAME}"

TAIL=""
LINES=""
CLEAR=""

# Parse options
while getopts "tn:c" opt; do
  case $opt in
    t) TAIL=1 ;;
    n) LINES="$OPTARG" ;;
    c) CLEAR=1 ;;
    *) echo "Usage: $0 <session-name> [-t] [-n <N>] [-c]" >&2; exit 1 ;;
  esac
done

# Check the window exists
if ! tmux has-session -t "$TMUX_SESSION" 2>/dev/null ||
   ! tmux list-windows -t "$TMUX_SESSION" -F '#{window_name}' 2>/dev/null | grep -qx "$WINDOW"; then
  echo "NOT_FOUND" >&2
  exit 1
fi

# Capture pane output
# -p : print to stdout
# -S - : start from beginning of history (negative means from start of history)
# -E - : end at current view (default)
CAPTURE=$(tmux capture-pane -t "$TMUX_SESSION:$WINDOW" -p -S - -E - 2>/dev/null || true)

# Strip trailing empty lines (keep them for potential "still running" detection)
# but remove the [BGR_EXIT:...] marker line from the display
# || true avoids pipefail issues when sed produces no output
CAPTURE=$(echo "$CAPTURE" | sed '$ { /^\[BGR_EXIT:[0-9]\+\]$/d; }' || true)

if [ -n "$LINES" ]; then
  CAPTURE=$(echo "$CAPTURE" | tail -n "$LINES")
elif [ -n "$TAIL" ]; then
  CAPTURE=$(echo "$CAPTURE" | tail -n 20)
fi

# Output
if [ -n "$CAPTURE" ]; then
  echo "$CAPTURE"
else
  echo "(no output yet)"
fi

# Optionally clear the pane
if [ -n "$CLEAR" ]; then
  tmux send-keys -t "$TMUX_SESSION:$WINDOW" "clear" Enter
fi
