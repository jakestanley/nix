#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/deploy-adler.sh [--test] [--allow-dirty] [--no-screen]

  --test         Run nixos-rebuild test instead of switch.
  --allow-dirty  Skip the clean git tree check.
  --no-screen    Run directly instead of re-execing inside screen.
  -h, --help     Show this help text.
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MODE="switch"
ALLOW_DIRTY=false
USE_SCREEN=true
SCREEN_SESSION="deploy-adler"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --test)
      MODE="test"
      ;;
    --allow-dirty)
      ALLOW_DIRTY=true
      ;;
    --no-screen)
      USE_SCREEN=false
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

if [[ "$ALLOW_DIRTY" != true ]] && [[ -n "$(git -C "$REPO_DIR" status --porcelain)" ]]; then
  echo "Refusing to deploy: repo has uncommitted changes." >&2
  echo "Commit or stash them first, or rerun with --allow-dirty." >&2
  exit 1
fi

cd "$REPO_DIR"

if [[ "$USE_SCREEN" == true ]] && [[ -z "${STY:-}" ]]; then
  if ! command -v screen >/dev/null 2>&1; then
    echo "screen is not installed; continuing without it." >&2
  else
    screen_cmd=(./scripts/deploy-adler.sh --no-screen)
    if [[ "$MODE" == "test" ]]; then
      screen_cmd+=(--test)
    fi
    if [[ "$ALLOW_DIRTY" == true ]]; then
      screen_cmd+=(--allow-dirty)
    fi

    printf -v screen_cmd_str '%q ' "${screen_cmd[@]}"
    exec screen -S "$SCREEN_SESSION" bash -lc "cd '$REPO_DIR' && $screen_cmd_str"
  fi
fi

sudo nixos-rebuild "$MODE" --flake .#adler -L
