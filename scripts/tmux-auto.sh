#!/usr/bin/env bash
set -euo pipefail

# Attach to the shared "anonymous" tmux session when no args are provided.
# If a session already exists, reuse it; otherwise create a new one.
session="anonymous"

if [[ $# -gt 0 ]]; then
  exec tmux "$@"
fi

if [[ -n "${TMUX-}" ]]; then
  exec tmux
fi

if tmux has-session -t "$session" >/dev/null 2>&1; then
  exec tmux attach-session -t "$session"
fi

exec tmux new-session -s "$session"
