#!/bin/bash
# kill.sh — Kill a background tmux window
# Usage: ./scripts/kill.sh <session-name>
#
# This kills the process's window inside the shared "background-tasks" session.
# Any process running in it will receive SIGHUP. Use send-keys.sh to send
# gentler signals (e.g., C-c) before killing if you want a clean shutdown.
# Killing the last window also ends the session; the next run.sh recreates it.

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
  echo "Session '$SESSION_NAME' not found (no window '$TMUX_SESSION:$WINDOW')." >&2
  exit 1
fi

echo "Killing session '$SESSION_NAME' (window: '$TMUX_SESSION:$WINDOW')..."
tmux kill-window -t "$TMUX_SESSION:$WINDOW"

if tmux has-session -t "$TMUX_SESSION" 2>/dev/null &&
   tmux list-windows -t "$TMUX_SESSION" -F '#{window_name}' 2>/dev/null | grep -qx "$WINDOW"; then
  echo "Error: failed to kill window '$SESSION_NAME'." >&2
  exit 1
fi

echo "Session '$SESSION_NAME' killed."
