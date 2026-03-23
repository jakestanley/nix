#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/deploy-turing.sh [personal|work] [--profile personal|work] [--allow-dirty]

  personal|work  Select the dock/profile flake output (default: personal).
  --profile      Same as positional profile argument.
  --allow-dirty  Skip the clean git tree check.
  -h, --help     Show this help text.
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ALLOW_DIRTY=false
PROFILE="personal"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --allow-dirty)
      ALLOW_DIRTY=true
      ;;
    --profile)
      if [[ $# -lt 2 ]]; then
        echo "--profile requires an argument: personal|work" >&2
        usage >&2
        exit 1
      fi
      PROFILE="$2"
      shift
      ;;
    personal|work)
      PROFILE="$1"
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

if [[ "$PROFILE" != "personal" && "$PROFILE" != "work" ]]; then
  echo "Unsupported profile: $PROFILE (expected: personal|work)" >&2
  exit 1
fi

FLAKE_TARGET="turing-${PROFILE}"

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

NIX_BIN="$(command -v nix)"
if [[ -z "$NIX_BIN" ]]; then
  echo "Could not find 'nix' in PATH." >&2
  exit 1
fi

sudo -H "$NIX_BIN" \
  --extra-experimental-features "nix-command flakes" \
  run ".#darwin-rebuild" -- \
  switch --flake ".#${FLAKE_TARGET}"
