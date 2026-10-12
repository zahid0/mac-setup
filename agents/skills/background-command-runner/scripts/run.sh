#!/bin/bash
# run.sh — Start a command in a persistent tmux window
# Usage: ./scripts/run.sh <session-name> "<shell-command>"
#
# All processes live in a single shared tmux session named "background-tasks".
# Each process gets its own window named "bgr-<session-name>".
#
# The shell-command is sent literally to the tmux shell.
# Use single quotes around the command to prevent the calling
# shell from expanding variables prematurely.
#
# Example:
#   ./scripts/run.sh my-srv 'npm run dev'
#   ./scripts/run.sh my-srv 'while true; do echo tick; sleep 1; done'

set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 <session-name> <shell-command>" >&2
  exit 1
fi

SESSION_NAME="$1"
shift
CMD="$*"

# Validate session name: only a-z, 0-9, hyphens
if [[ ! "$SESSION_NAME" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  echo "Error: session name must match ^[a-z0-9][a-z0-9-]*$ (got '$SESSION_NAME')" >&2
  exit 1
fi

# One shared session, one window per process (bgr- prefix avoids collisions)
TMUX_SESSION="background-tasks"
WINDOW="bgr-${SESSION_NAME}"

# Check if a window with this name already exists
if tmux has-session -t "$TMUX_SESSION" 2>/dev/null &&
   tmux list-windows -t "$TMUX_SESSION" -F '#{window_name}' 2>/dev/null | grep -qx "$WINDOW"; then
  echo "Error: session '$SESSION_NAME' already exists (window '$WINDOW' in '$TMUX_SESSION')." >&2
  echo "  Use ./scripts/send-keys.sh to interact, ./scripts/restart.sh to restart," >&2
  echo "  or ./scripts/kill.sh to kill it first." >&2
  exit 1
fi

if ! tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
  # Create the shared session; its first window is ours
  # -x and -y set the initial pane size (wide, tall scrollback).
  tmux new-session -d -s "$TMUX_SESSION" -n "$WINDOW" -x 200 -y 10000
else
  # Session exists — add a new window for this process
  tmux new-window -t "$TMUX_SESSION" -n "$WINDOW"
fi

tmux send-keys -t "$TMUX_SESSION:$WINDOW" "export BGR_SESSION='$SESSION_NAME'" Enter \; \
  send-keys -t "$TMUX_SESSION:$WINDOW" "clear" Enter

# Give the shell a moment to start
sleep 0.3

# Send the command with an exit-code tracker appended as a single line.
# Using single-line form to avoid terminal echo noise from the second line.
# $? is escaped so bash passes it literally; tmux shell evaluates it at runtime.
tmux send-keys -t "$TMUX_SESSION:$WINDOW" "$CMD; echo \"[BGR_EXIT:\$?]\"" Enter
#                                                         ^ literal $? sent to tmux shell

echo "Started session '$SESSION_NAME'."
echo "  Tmux window: $TMUX_SESSION:$WINDOW"
echo "  Command: $CMD"
echo ""
echo "  View output:  ./scripts/output.sh $SESSION_NAME"
echo "  Check status: ./scripts/status.sh $SESSION_NAME"
echo "  Send keys:    ./scripts/send-keys.sh $SESSION_NAME"
echo "  Restart:      ./scripts/restart.sh $SESSION_NAME"
echo "  Kill:         ./scripts/kill.sh $SESSION_NAME"
