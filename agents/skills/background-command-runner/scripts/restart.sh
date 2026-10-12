#!/bin/bash
# restart.sh — Restart a command in an existing window
# Usage: ./scripts/restart.sh <session-name> "<new-command>"
#
# Sends Ctrl+C to stop any running process, waits, then
# runs the new command with exit-code tracking.

set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 <session-name> <new-command>" >&2
  exit 1
fi

SESSION_NAME="$1"
shift
CMD="$*"
TMUX_SESSION="background-tasks"
WINDOW="bgr-${SESSION_NAME}"

if ! tmux has-session -t "$TMUX_SESSION" 2>/dev/null ||
   ! tmux list-windows -t "$TMUX_SESSION" -F '#{window_name}' 2>/dev/null | grep -qx "$WINDOW"; then
  echo "Error: session '$SESSION_NAME' not found (window: '$TMUX_SESSION:$WINDOW')." >&2
  echo "  Start one first: ./scripts/run.sh $SESSION_NAME '<command>'" >&2
  exit 1
fi

# Send Ctrl+C to stop any running process
echo "Sending Ctrl+C to session '$SESSION_NAME'..."
tmux send-keys -t "$TMUX_SESSION:$WINDOW" C-c

# Wait for the process to terminate
sleep 1

# Send the new command with exit-code tracker on a single line
echo "Running: $CMD"
tmux send-keys -t "$TMUX_SESSION:$WINDOW" "$CMD; echo \"[BGR_EXIT:\$?]\"" Enter

echo "Restarted session '$SESSION_NAME' with: $CMD"
