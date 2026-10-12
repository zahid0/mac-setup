---
name: background-command-runner
description: >-
  Runs long-lived background processes (dev servers, watchers, databases, API
  backends) in persistent tmux windows on a dedicated private tmux server. Start
  processes, read output, check exit codes, send signals, restart, kill. Use for
  processes that stay alive or stream logs; NOT for quick one-off commands (use
  bash exec).
---

# Background Command Runner

Run long-lived processes in tmux so they survive across tool calls. Everything
lives on a **dedicated private tmux server** selected with `-L bgr` — a fixed,
skill-owned socket that is entirely separate from the user's normal tmux
sessions. On that server: one session `tasks`, one window per process named
`bgr-<name>`. Because the window keeps an interactive shell alive after the
command exits, the pane stays a durable transcript: re-read it, check the exit
code, send new keys.

## ⚠️ Isolation rule (read first)

**Always pass `-L bgr` to every tmux command in this skill.** Never run a bare
`tmux ...` command and never run `tmux kill-server` / `kill-session` without
`-L bgr` — those act on the default server and will destroy the user's own tmux
sessions. `-L bgr` uses a separate socket (e.g. `/tmp/tmux-<uid>/bgr`), so your
commands can only ever see the skill's windows. If you must wipe everything:
`tmux -L bgr kill-server` (skill server only) — never `tmux kill-server`.

## How it works

The window is *not* one-shot: `CMD` is sent to a live shell, so when the command
finishes the shell remains and the pane holds its output. To tell "still
running" from "finished", the command is wrapped as `CMD; echo "[BGR_EXIT:$?]"`.
That marker only appears once `CMD` exits, carrying its exit code — so status is
just a grep for it. The shell, not the command, owns the pane, and the marker is
how you detect the command ending.

## Commands

All commands use the private socket `bgr` (`-L bgr`) and target the window
`tasks:bgr-<name>`. Replace `NAME` and `CMD`, and single-quote `CMD` so `$` and
backticks reach tmux literally. These are examples, not limits — use any tmux
command the task needs (`resize-pane`, `wait-for`, etc.), always with `-L bgr`.

```bash
# Start
tmux -L bgr new-session -d -s tasks -n bgr-NAME -x 200 2>/dev/null \
  || tmux -L bgr new-window -t tasks -n bgr-NAME
tmux -L bgr set-option -g history-limit 10000                 # future windows
tmux -L bgr set-option -t tasks:bgr-NAME history-limit 10000  # this window
sleep 0.3                                                     # let the shell reach its prompt
tmux -L bgr send-keys -t tasks:bgr-NAME "CMD; echo \"[BGR_EXIT:\$?]\"" Enter

# Output: last 50 real lines. capture-pane pads the pane with blank rows down to
# its height, so drop empty lines before tailing — otherwise you tail blanks.
tmux -L bgr capture-pane -t tasks:bgr-NAME -p -S - | grep -v '^$' | tail -50

# Status: no marker = RUNNING, marker = EXITED <code>
tmux -L bgr capture-pane -t tasks:bgr-NAME -p -S - | grep -o '\[BGR_EXIT:[0-9]*\]' | tail -1

# Signals / new command (C-c SIGINT, C-d EOF, C-z suspend)
tmux -L bgr send-keys -t tasks:bgr-NAME C-c
tmux -L bgr send-keys -t tasks:bgr-NAME "CMD" Enter

# List / kill
tmux -L bgr list-windows -t tasks -F '#{window_name}'
tmux -L bgr kill-window -t tasks:bgr-NAME
```

## Reliable logs

The scrollback is a convenience, not an archive: heavy output scrolls old lines
away. For a lossless log, tee the pane to a file with `pipe-pane`:

```bash
tmux -L bgr pipe-pane -t tasks:bgr-NAME -o 'cat >> /tmp/bgr-NAME.log'  # start
tmux -L bgr pipe-pane -t tasks:bgr-NAME                                # stop
```

The file records raw terminal bytes (ANSI color codes and prompt redraws
included) and only captures output from the moment `pipe-pane` starts — pipe
through a filter if you need clean text.

## Notes

- Names: `[a-z0-9-]` only, unique per process.
- `-x 200` widens the pane so long lines wrap less (applies when detached; an attached client overrides the size); `history-limit` sets the real buffer depth.
- `[BGR_EXIT:<code>]` is the exit sentinel — avoid commands that print it.
- If the window's shell exits entirely (e.g. you started tmux with the command as its argument rather than sending keys), the pane dies and takes the transcript with it. Sending keys keeps the shell alive — and `tmux -L bgr set-option -g remain-on-exit on` preserves dead panes for later inspection.
- After Ctrl+C the window shell survives; send a new command instead of restarting.
- The `bgr` server persists across agent restarts and is invisible to the user's own tmux work — list windows to rediscover processes; killing the last window ends the `tasks` session, but the next start recreates it.
