#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/deploy-turing.sh [--allow-dirty]

  --allow-dirty  Skip the clean git tree check.
  -h, --help     Show this help text.
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ALLOW_DIRTY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
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

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This deploy target is macOS-only (Darwin)." >&2
  exit 1
fi

if [[ "$(uname -m)" != "arm64" ]]; then
  echo "This deploy target expects Apple Silicon (arm64)." >&2
  exit 1
fi

if [[ "$ALLOW_DIRTY" != true ]] && [[ -n "$(git -C "$REPO_DIR" status --porcelain)" ]]; then
  echo "Refusing to deploy: repo has uncommitted changes." >&2
  echo "Commit or stash them first, or rerun with --allow-dirty." >&2
  exit 1
fi

cd "$REPO_DIR"

nix \
  --extra-experimental-features "nix-command flakes" \
  build ".#homeConfigurations.turing.activationPackage" \
  --no-write-lock-file

"$REPO_DIR/result/activate"
