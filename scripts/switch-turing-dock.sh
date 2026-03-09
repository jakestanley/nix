#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/switch-turing-dock.sh <personal|work>

Switches between declarative Dock profiles on host turing by rebuilding:
  personal -> .#turing-personal
  work     -> .#turing-work
EOF
}

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 1
fi

case "$1" in
  personal)
    target="turing-personal"
    ;;
  work)
    target="turing-work"
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    echo "Unknown profile: $1" >&2
    usage >&2
    exit 1
    ;;
esac

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This switch target is macOS-only (Darwin)." >&2
  exit 1
fi

if [[ "$(uname -m)" != "arm64" ]]; then
  echo "This switch target expects Apple Silicon (arm64)." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

NIX_BIN="$(command -v nix)"
if [[ -z "$NIX_BIN" ]]; then
  echo "Could not find 'nix' in PATH." >&2
  exit 1
fi

sudo -H "$NIX_BIN" \
  --extra-experimental-features "nix-command flakes" \
  run ".#darwin-rebuild" -- \
  switch --flake ".#${target}"
