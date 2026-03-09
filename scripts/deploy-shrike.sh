#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/deploy-shrike.sh [--test] [--allow-dirty]

  --test         Run nixos-rebuild test instead of switch.
  --allow-dirty  Skip the clean git tree check.
  -h, --help     Show this help text.
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MODE="switch"
ALLOW_DIRTY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --test)
      MODE="test"
      ;;
    --allow-dirty)
      ALLOW_DIRTY=true
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

export DIRTY_LABEL=""
if [[ "$ALLOW_DIRTY" == true ]] ; then
  DIRTY_LABEL=" (dirty)"
fi

export NIXOS_LABEL=""
NIXOS_LABEL="$(date '+%Y-%m-%d+%H:%M')_$(git rev-parse --short HEAD)$DIRTY_LABEL"

sudo nixos-rebuild "$MODE" --flake .#shrike -L
