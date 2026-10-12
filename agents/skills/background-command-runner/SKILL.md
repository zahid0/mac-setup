---
name: background-command-runner
description: >-
  Manages long-running background processes (dev servers, watchers, build tools,
  database servers, API backends, file watchers, local proxies, application
  runtimes) via persistent tmux sessions. Start, monitor, stop, restart commands,
  capture output and exit codes, send signals (Ctrl+C, etc.). Ideal for processes
  that stay alive or produce ongoing logs. NOT for one-off commands that return
  immediately — use bash exec for those.
---

# 🔧 Background Command Runner

Manages **long-running, persistent background processes** using one shared tmux
session named `background-tasks`. Each process runs in its own window
(`bgr-<name>`) inside that session. Every window keeps a shell alive after the
command exits, so you can inspect output, check exit codes, send signals, and
restart commands — all without losing context.

## 🎯 When to Use

**Perfect for:**
- Dev servers, watchers, build tools (`npm run dev`, `tsc --watch`)
- Database servers, API backends, local proxies
- Any process that runs for minutes/hours and produces ongoing output

**NOT for:**
- One-off commands that complete quickly (`ls`, `grep`, `npm install`)
- Commands that should block the agent — use regular `bash` exec instead

## 📋 Prerequisites

- **tmux** installed (`brew install tmux` / `apt install tmux`)
- Session names: lowercase letters, numbers, hyphens only, unique
  (each maps to a distinct window in `background-tasks`)
- The shared session is auto-created on first use — no setup needed

## 🚀 Usage

All scripts are in `scripts/` and accept the session name as the first argument.

### Start a Process

```bash
./scripts/run.sh <session-name> "<shell-command>"
```

```bash
./scripts/run.sh dev-server 'npm run dev'
./scripts/run.sh api-backend 'cd api && python -m uvicorn main:app --reload'
./scripts/run.sh logger 'while true; do echo "tick at $(date)"; sleep 1; done'
```

> **💡 Use single quotes** around the command so your shell doesn't expand `$`,
> backticks, etc. before tmux sees them. If the command itself must contain
> literal `$` (e.g., `$HOME`), single quotes preserve them.

### View Output

```bash
./scripts/output.sh <session-name>          # full buffer
./scripts/output.sh <session-name> -t       # last 20 lines
./scripts/output.sh <session-name> -n 50    # last 50 lines
```

### Check Status

```bash
./scripts/status.sh <session-name>
```

Returns one of:
- `RUNNING` — the command is still executing
- `EXITED <code>` — the command completed with exit code `<code>`
- `NOT_FOUND` — no window with that name exists

### Send Keys / Signals

```bash
./scripts/send-keys.sh <session-name> "<keys>"
```

tmux key syntax: `C-c` (SIGINT), `C-d` (EOF), `C-z` (suspend), `Enter`,
`Escape`, `BSpace`, `Tab`, arrows. Text is typed literally; spaces separate keys.

```bash
./scripts/send-keys.sh dev-server C-c                    # Stop
./scripts/send-keys.sh dev-server "npm run dev" Enter    # (Re)start
```

### Restart (Stop + Start)

```bash
./scripts/restart.sh <session-name> "<new-command>"
```

Sends Ctrl+C, waits briefly, then runs the new command in the same window.

### List Managed Processes

```bash
./scripts/list.sh
```

Shows all `bgr-` windows in the `background-tasks` session with status.

### Kill a Process

```bash
./scripts/kill.sh <session-name>
```

Kills the process's window (SIGHUP to running process). Killing the last window
also ends the session; the next `run.sh` recreates it automatically.

## 💡 Workflow Example: Poll Until Ready

```bash
./scripts/run.sh db 'pg_ctl start -D /opt/homebrew/var/postgres'

while true; do
  ./scripts/output.sh db -n 10 | grep -q "database system is ready" && break
  sleep 1
done
```

## 🔍 How It Works

1. `run.sh` ensures the `background-tasks` session exists (creates it on first
   use), then opens a window named `bgr-<session-name>` for the process
2. The command runs wrapped in an exit-code tracker:
   `COMMAND; echo "[BGR_EXIT:$?]"`
3. The window stays alive in a shell after the command completes — the shell
   waits for the next command
4. `status.sh` greps the pane for `[BGR_EXIT:<code>]`; `output.sh` captures the
   pane contents and strips the marker

## ⚠️ Notes & Limitations

- Output comes from the **tmux scrollback buffer**. Heavy output scrolls old
  lines away; use `-n <N>` to get the last N lines.
- Exit detection relies on the `[BGR_EXIT:` marker. Avoid commands that print
  this exact string — detection becomes unreliable.
- All processes share one session: killing `background-tasks` kills everything.
  Use `kill.sh` per process instead.
- If the agent restarts, the session persists. Run `list.sh` to rediscover
  processes at the start of a new session.

### Ctrl+C and compound commands

Ctrl+C on a compound command (`while ...; done; echo "[BGR_EXIT:$?]"`) may abort
the whole thing without running the tracker, so `status.sh` can show `RUNNING`
after a kill. To confirm: check output for `^C` with no `[BGR_EXIT:...]` after
it. Then send a new command (or use `restart.sh`, which handles this).

**After Ctrl+C the window shell is still alive** — only the running process was
interrupted. Send new commands immediately without killing the window.
