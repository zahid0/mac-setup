#!/bin/bash
# list.sh — List all managed background processes
# Usage: ./scripts/list.sh
#
# Lists all bgr-* windows in the shared "background-tasks" session.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TMUX_SESSION="background-tasks"

if ! tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
  echo "No active background sessions."
  exit 0
fi

# Find all windows with the bgr- prefix in the shared session
TMUX_WINDOWS=$(tmux list-windows -t "$TMUX_SESSION" -F '#{window_name}' 2>/dev/null | grep '^bgr-' || true)

if [ -z "$TMUX_WINDOWS" ]; then
  echo "No active background sessions."
  exit 0
fi

echo "Active background sessions (tmux session: $TMUX_SESSION):"
echo "--------------------------------------------------------"

while IFS= read -r window; do
  # Strip the bgr- prefix to get the user-friendly name
  NAME="${window#bgr-}"
  
  # Get status
  STATUS=$("$SCRIPT_DIR/status.sh" "$NAME" 2>/dev/null || echo "UNKNOWN")
  
  # Get last activity time from tmux
  CREATED=$(tmux list-windows -t "$TMUX_SESSION" -F '#{window_name} #{window_activity}' 2>/dev/null | awk -v w="$window" '$1 == w { print $2 }')
  if [ -n "$CREATED" ]; then
    CREATED_STR=$(date -r "$CREATED" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "unknown")
  else
    CREATED_STR="unknown"
  fi
  
  printf "  %-25s %-15s (last activity: %s)\n" "$NAME" "$STATUS" "$CREATED_STR"
done <<< "$TMUX_WINDOWS"

echo ""
echo "Commands:"
echo "  ./scripts/output.sh <name>   — view output"
echo "  ./scripts/status.sh <name>   — check status"
echo "  ./scripts/send-keys.sh <name> — send keys/signals"
echo "  ./scripts/restart.sh <name>  — restart command"
echo "  ./scripts/kill.sh <name>     — kill window"
