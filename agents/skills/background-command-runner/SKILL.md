---
name: background-command-runner
description: >-
  Runs long-lived background processes (dev servers, watchers, databases, API
  backends) in persistent tmux windows on the default tmux server, inside a
  dedicated session. Start processes, read output, check exit codes, send
  signals, restart, kill. Use for processes that stay alive or stream logs; NOT
  for quick one-off commands (use bash exec).
---

# Background Command Runner

Run long-lived processes in tmux so they survive across tool calls. Everything
lives in a **dedicated session named `bgr`** on the default tmux server, one
window per process named `bgr-<name>`. Because the window keeps an interactive
shell alive after the command exits, the pane stays a durable transcript:
re-read it, check the exit code, send new keys. You can hop in anytime with
`tmux attach -t bgr`.

## ⚠️ Isolation rule (read first)

**Always target the `bgr` session (and `bgr-` window names) in every tmux
command in this skill.** Never run `tmux kill-server` — it would destroy the
user's own tmux sessions. Session-scoped commands are safe:
`tmux kill-session -t bgr` wipes only the skill's processes. The session name
`bgr` is deliberately unusual so it won't collide with the user's own sessions;
if `tmux new-session -t bgr ...` ever shows an unexpected session, don't touch
it — pick a different session name for the skill and use it consistently.

The skill shares the user's tmux server, so it inherits the user's
`~/.tmux.conf` (status bar, bindings, plugins). This is a feature: you can
attach and browse logs with your normal setup.

## How it works

The window is *not* one-shot: `CMD` is sent to a live shell, so when the command
finishes the shell remains and the pane holds its output. To tell "still
running" from "finished", the command is wrapped as `CMD; echo "[BGR_EXIT:$?]"`.
That marker only appears once `CMD` exits, carrying its exit code — so status is
just a grep for it. The shell, not the command, owns the pane, and the marker is
how you detect the command ending.

## Commands

All commands use the plain default socket and target the window
`bgr:bgr-<name>`. Replace `NAME` and `CMD`, and **single-quote the whole
`send-keys` argument** (CMD *and* the sentinel) so `$`, backticks, and `$(…)` are
expanded by the *pane's* shell, not the shell running this skill — a double-quoted
argument would expand them here instead, and break on any `"` inside CMD. Escape a
single quote inside CMD as `'\''`. These are examples, not limits — use any tmux
command the task needs (`resize-pane`, `wait-for`, etc.), always targeting the
`bgr` session.

```bash
# Start. One invocation: set the scrollback cap BEFORE any window exists, then
# create the session. history-limit applies only to windows created after it is
# set, so it must precede new-session.
tmux set-option -g history-limit 10000 \; \
  new-session -d -s bgr -n bgr-NAME -x 200 2>/dev/null \
  || tmux new-window -t bgr -n bgr-NAME
sleep 0.3   # let the shell reach its prompt (heavy shell rc files may need more)
tmux send-keys -t bgr:bgr-NAME 'CMD; echo "[BGR_EXIT:$?]"' Enter

# Output: last 50 real lines. capture-pane pads the pane with blank rows down to
# its height, so drop empty lines before tailing — otherwise you tail blanks.
# This strips genuinely blank lines from program output too; -J joins wrapped
# lines. If the window is gone, capture-pane errors — that means GONE, not RUNNING.
tmux capture-pane -t bgr:bgr-NAME -p -S - -J | grep -v '^$' | tail -50

# Status: no marker = RUNNING, marker = EXITED <code>. The marker reported is the
# LAST one in the scrollback, so after a first run it is stale for every later
# run until you clear it (see below).
tmux capture-pane -t bgr:bgr-NAME -p -S - | grep -o '\[BGR_EXIT:[0-9]*\]' | tail -1

# Signals (C-c SIGINT, C-d EOF, C-z suspend)
tmux send-keys -t bgr:bgr-NAME C-c

# Re-running in the same window? Wipe the old sentinel first, or the status check
# reports the PREVIOUS run's exit code while the new command is still running.
# clear-history alone is not enough — the marker can still sit on the visible
# screen. Kill the window instead if you want the old transcript to stay readable.
tmux send-keys -t bgr:bgr-NAME 'clear' Enter
tmux clear-history -t bgr:bgr-NAME
tmux send-keys -t bgr:bgr-NAME 'CMD; echo "[BGR_EXIT:$?]"' Enter

# List / kill
tmux list-windows -t bgr -F '#{window_name}'
tmux kill-window -t bgr:bgr-NAME

# Attach to browse logs by hand
tmux attach -t bgr
```

## Reliable logs

The scrollback is a convenience, not an archive: heavy output scrolls old lines
away. For a lossless log, tee the pane to a file with `pipe-pane`:

```bash
tmux pipe-pane -t bgr:bgr-NAME -o 'cat >> /tmp/bgr-NAME.log'  # start
tmux pipe-pane -t bgr:bgr-NAME                               # stop
```

The file records raw terminal bytes (ANSI color codes and prompt redraws
included) and only captures output from the moment `pipe-pane` starts — pipe
through a filter if you need clean text. `>>` concatenates successive runs into
one file with no separator; use `>` to truncate per run.

## Notes

- Names: `[a-z0-9-]` only, unique per process.
- `-x 200` widens the pane so long lines wrap less (applies when detached; an attached client overrides the size); `history-limit` sets the real buffer depth and applies only to windows created after it is set.
- `[BGR_EXIT:<code>]` is the exit sentinel — avoid commands that print it.
- The status marker is the last one in the scrollback, so it is stale for every run after the first until you clear it (clear + clear-history) or kill the window. A `capture-pane` error means the window is gone, not running.
- If the window's shell exits entirely (e.g. you started tmux with the command as its argument rather than sending keys), the pane dies and takes the transcript with it. Sending keys keeps the shell alive — and `tmux set-option -t bgr remain-on-exit on` preserves dead panes in the `bgr` session for later inspection (session-scoped, so it doesn't change the user's other sessions).
- After Ctrl+C the window shell survives; clear the sentinel (or kill the window) before reusing it — don't send a new command over the old marker.
- The `bgr` session lives on the user's default tmux server, so it survives agent restarts and shows up in `tmux ls` for easy manual attachment. List windows to rediscover processes; killing the last window ends the `bgr` session, but the next start recreates it.
- Because the session is shared with the user's server, scope any option changes to `-t bgr` rather than `-g` when possible (the `history-limit` line above is global by necessity — run it with care or convert it to a session option if the user objects).
