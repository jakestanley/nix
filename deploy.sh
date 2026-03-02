#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./deploy.sh [--update] [--allow-dirty]

  --update       Update the pinned nixpkgs input before deploying.
  --allow-dirty  Skip the clean git tree check.
  -h, --help     Show this help text.
EOF
}

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_REF="$REPO_DIR#shrike"
UPDATE_INPUT=false
ALLOW_DIRTY=false
NIX_CONFIG_WITH_FLAKES=$'experimental-features = nix-command flakes'

if [[ -n "${NIX_CONFIG:-}" ]]; then
  NIX_CONFIG_WITH_FLAKES+=$'\n'
  NIX_CONFIG_WITH_FLAKES+="$NIX_CONFIG"
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --update)
      UPDATE_INPUT=true
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

if [[ "$UPDATE_INPUT" == true ]]; then
  echo "Updating nixpkgs lock entry..."
  if ! env NIX_CONFIG="$NIX_CONFIG_WITH_FLAKES" nix flake lock --update-input nixpkgs; then
    echo "nix flake lock --update-input nixpkgs failed." >&2
    echo "If you changed the pinned nixpkgs revision in flake.nix, verify it resolves and retry." >&2
    exit 1
  fi
fi

echo "Validating flake..."
if ! env NIX_CONFIG="$NIX_CONFIG_WITH_FLAKES" nix flake show "$REPO_DIR"; then
  echo "nix flake show failed. Not switching." >&2
  exit 1
fi

echo "Running dry-run..."
if ! sudo env NIX_CONFIG="$NIX_CONFIG_WITH_FLAKES" nixos-rebuild dry-run --flake "$FLAKE_REF"; then
  echo "nixos-rebuild dry-run failed. Not switching." >&2
  exit 1
fi

echo "Switching system..."
if ! sudo env NIX_CONFIG="$NIX_CONFIG_WITH_FLAKES" nixos-rebuild switch --flake "$FLAKE_REF"; then
  echo "nixos-rebuild switch failed." >&2
  exit 1
fi

echo "Deployment complete."
