#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="/etc/nixos"

echo "Deploying NixOS config from:"
echo "  $REPO_DIR"
echo "to:"
echo "  $TARGET_DIR"
echo

if [[ $EUID -ne 0 ]]; then
  echo "Re-running as root..."
  exec sudo "$0" "$@"
fi

echo "Syncing files..."
rsync -a --delete \
  --exclude '.git' \
  "$REPO_DIR/" "$TARGET_DIR/"

echo "Rebuilding system..."
nixos-rebuild switch

echo "Done."
