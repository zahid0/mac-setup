#!/bin/bash
# send-keys.sh — Send keys/signals to a background tmux window
# Usage: ./scripts/send-keys.sh <session-name> <keys...>
#
# Key formats (tmux send-keys syntax):
#   C-c       Ctrl+C (SIGINT)
#   C-d       Ctrl+D (EOF)
#   C-z       Ctrl+Z (SIGTSTP)
#   Enter     Carriage return
#   Escape    Escape key
#   BSpace    Backspace
#   Tab       Tab
#   Up        Arrow up
#   Down      Arrow down
#   Text is typed literally; separate multiple arguments with spaces
#
# Examples:
#   ./scripts/send-keys.sh my-srv C-c                  # Send SIGINT
#   ./scripts/send-keys.sh my-srv 'npm run dev' Enter   # Type a command and run it
#   ./scripts/send-keys.sh my-srv C-c 'npm run dev' Enter  # Ctrl+C then restart

set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 <session-name> <key1> [key2 ...]" >&2
  echo "  Special keys: C-c, C-d, C-z, Enter, Escape, BSpace, Tab, Up, Down" >&2
  echo "  Other text is typed literally." >&2
  exit 1
fi

SESSION_NAME="$1"
shift
TMUX_SESSION="background-tasks"
WINDOW="bgr-${SESSION_NAME}"

if ! tmux has-session -t "$TMUX_SESSION" 2>/dev/null ||
   ! tmux list-windows -t "$TMUX_SESSION" -F '#{window_name}' 2>/dev/null | grep -qx "$WINDOW"; then
  echo "Error: session '$SESSION_NAME' not found (window: '$TMUX_SESSION:$WINDOW')." >&2
  echo "  Start one with: ./scripts/run.sh $SESSION_NAME '<command>'" >&2
  exit 1
fi

# Send all keys to the tmux pane
# We pass all remaining arguments directly to tmux send-keys.
# tmux handles key name parsing (C-c, etc.) natively.
tmux send-keys -t "$TMUX_SESSION:$WINDOW" "$@"

echo "Sent keys to session '$SESSION_NAME'."
echo "  Keys: $*"
echo "  View output: ./scripts/output.sh $SESSION_NAME"
