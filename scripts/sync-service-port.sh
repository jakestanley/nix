#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/sync-service-port.sh SERVICE [--repo-dir PATH] [--allow-dirty]

Sync sources/service-ports/SERVICE.nix from:
  homelab-infra/registry.yaml -> services.<service>.upstream.port

Options:
  --repo-dir PATH  Use an existing local homelab-infra checkout instead of cloning.
  --allow-dirty    Allow overwriting the target file when the repo has other changes.
  -h, --help       Show this help text.
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
INFRA_REPO_URL="git@github.com:jakestanley/homelab-infra.git"
REGISTRY_FILE="registry.yaml"
INFRA_REPO_DIR=""
ALLOW_DIRTY=false
SERVICE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-dir)
      [[ $# -ge 2 ]] || {
        echo "--repo-dir requires a path" >&2
        exit 1
      }
      INFRA_REPO_DIR="$2"
      shift
      ;;
    --allow-dirty)
      ALLOW_DIRTY=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      if [[ -n "$SERVICE" ]]; then
        echo "Unexpected extra positional argument: $1" >&2
        usage >&2
        exit 1
      fi
      SERVICE="$1"
      ;;
  esac
  shift
done

if [[ -z "$SERVICE" ]]; then
  echo "SERVICE is required" >&2
  usage >&2
  exit 1
fi

if ! [[ "$SERVICE" =~ ^[a-z0-9-]+$ ]]; then
  echo "Unsupported service name: $SERVICE" >&2
  echo "Use lowercase letters, digits, and hyphens only." >&2
  exit 1
fi

if [[ "$ALLOW_DIRTY" != true ]] && [[ -n "$(git -C "$REPO_DIR" status --porcelain)" ]]; then
  echo "Refusing to sync: repo has uncommitted changes." >&2
  echo "Commit or stash them first, or rerun with --allow-dirty." >&2
  exit 1
fi

cleanup() {
  if [[ -n "${TEMP_DIR:-}" && -d "${TEMP_DIR:-}" ]]; then
    rm -rf "$TEMP_DIR"
  fi
}

trap cleanup EXIT

if [[ -z "$INFRA_REPO_DIR" ]]; then
  TEMP_DIR="$(mktemp -d)"
  git clone --depth 1 "$INFRA_REPO_URL" "$TEMP_DIR/homelab-infra" >/dev/null
  INFRA_REPO_DIR="$TEMP_DIR/homelab-infra"
fi

if [[ ! -d "$INFRA_REPO_DIR/.git" ]]; then
  echo "Not a git repository: $INFRA_REPO_DIR" >&2
  exit 1
fi

REGISTRY_PATH="$INFRA_REPO_DIR/$REGISTRY_FILE"

if [[ ! -f "$REGISTRY_PATH" ]]; then
  echo "Registry file not found: $REGISTRY_PATH" >&2
  exit 1
fi

TARGET_DIR="$REPO_DIR/sources/service-ports"
TARGET_FILE="$TARGET_DIR/$SERVICE.nix"
mkdir -p "$TARGET_DIR"

service_pattern="^  ${SERVICE}:$"

PORT="$(
  sed -n '/^services:/,/^[^[:space:]]/p' "$REGISTRY_PATH" \
    | sed -n "/$service_pattern/,/^  [^[:space:]]/p" \
    | sed -n '/^    upstream:/,/^    [^[:space:]]/p' \
    | sed -n 's/^      port:[[:space:]]*\([0-9][0-9]*\).*$/\1/p'
)"

if [[ -z "$PORT" ]]; then
  echo "Failed to resolve services.$SERVICE.upstream.port from $REGISTRY_PATH" >&2
  exit 1
fi

if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
  echo "Resolved port is not numeric: $PORT" >&2
  exit 1
fi

SOURCE_REV="$(git -C "$INFRA_REPO_DIR" rev-parse HEAD)"
SOURCE_REF="$(git -C "$INFRA_REPO_DIR" symbolic-ref --quiet --short HEAD || echo detached)"

cat > "$TARGET_FILE" <<EOF
{
  # Canonical local listen port for service '$SERVICE'.
  #
  # Synced from:
  # repo: $INFRA_REPO_URL
  # ref: $SOURCE_REF
  # rev: $SOURCE_REV
  # path: services.$SERVICE.upstream.port in $REGISTRY_FILE
  #
  # This value may be updated by scripts/sync-service-port.sh.
  # It must not be resolved dynamically during Nix evaluation or deployment.
  port = $PORT;
}
EOF

echo "Updated $TARGET_FILE"
echo "  source: $INFRA_REPO_URL @ $SOURCE_REV"
echo "  path:   services.$SERVICE.upstream.port"
echo "  port:   $PORT"
