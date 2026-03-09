#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/audit-turing-apps.sh

Reports:
  1) /Applications bundles not represented by declared nix-darwin casks
  2) Declared nix-darwin casks not installed in Homebrew
  3) Rosetta-era /usr/local Homebrew leftovers (Apple Silicon)

Exit codes:
  0 = no drift detected
  1 = drift detected
  2 = audit could not complete
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HOST_NAME="${HOST_NAME:-turing}"
FLAKE_REF="${REPO_DIR}#darwinConfigurations.${HOST_NAME}.config.homebrew.casks"

for cmd in nix brew /usr/bin/python3; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 2
  fi
done

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

declared_json="$tmpdir/declared-casks.json"
declared_casks="$tmpdir/declared-casks.txt"
installed_casks="$tmpdir/installed-casks.txt"
missing_casks="$tmpdir/missing-casks.txt"

expected_apps="$tmpdir/expected-apps.txt"
installed_apps="$tmpdir/installed-apps.txt"
apps_not_in_casks="$tmpdir/apps-not-in-casks.txt"

rosetta_leftovers="$tmpdir/rosetta-leftovers.txt"
legacy_formulae="$tmpdir/legacy-formulae.txt"
legacy_casks="$tmpdir/legacy-casks.txt"

echo "Resolving declared casks from ${FLAKE_REF}..."
if ! XDG_CACHE_HOME="$tmpdir" \
  nix --extra-experimental-features "nix-command flakes" \
  eval --json "$FLAKE_REF" >"$declared_json"; then
  echo "Failed to evaluate declared casks from flake output: $FLAKE_REF" >&2
  exit 2
fi

/usr/bin/python3 - "$declared_json" >"$declared_casks" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as f:
    casks = json.load(f)

for cask in casks:
    if isinstance(cask, str):
        print(cask)
        continue
    if isinstance(cask, dict):
        name = cask.get("name")
        if isinstance(name, str):
            print(name)
PY

sort -u "$declared_casks" -o "$declared_casks"
brew list --cask --full-name 2>/dev/null | sort -u >"$installed_casks" || true
comm -23 "$declared_casks" "$installed_casks" >"$missing_casks"

if [[ -s "$declared_casks" ]]; then
  declared_cask_args=()
  while IFS= read -r cask; do
    if [[ -n "$cask" ]]; then
      declared_cask_args+=("$cask")
    fi
  done <"$declared_casks"

  if [[ "${#declared_cask_args[@]}" -gt 0 ]] \
    && brew info --cask --json=v2 "${declared_cask_args[@]}" >"$tmpdir/cask-info.json" 2>/dev/null; then
    /usr/bin/python3 - "$tmpdir/cask-info.json" >"$expected_apps" <<'PY'
import json
import os
import sys

with open(sys.argv[1], "r", encoding="utf-8") as f:
    data = json.load(f)

apps = set()
for cask in data.get("casks", []):
    for artifact in cask.get("artifacts", []):
        if not isinstance(artifact, dict):
            continue
        for key in ("app", "suite"):
            if key not in artifact:
                continue
            entries = artifact[key]
            if not isinstance(entries, list):
                entries = [entries]
            for entry in entries:
                candidate = None
                if isinstance(entry, str):
                    candidate = entry
                elif isinstance(entry, list) and entry:
                    if isinstance(entry[0], str):
                        candidate = entry[0]
                elif isinstance(entry, dict):
                    target = entry.get("target")
                    if isinstance(target, str):
                        candidate = target
                if not candidate:
                    continue
                name = os.path.basename(candidate)
                if name.endswith(".app"):
                    apps.add(name)

for app in sorted(apps):
    print(app)
PY
  else
    : >"$expected_apps"
    echo "Warning: failed to derive app artifacts from declared casks." >&2
  fi
else
  : >"$expected_apps"
fi

if [[ -d /Applications ]]; then
  find /Applications -mindepth 1 -maxdepth 1 -type d -name '*.app' -exec basename {} \; | sort -u >"$installed_apps"
else
  : >"$installed_apps"
fi

comm -23 "$installed_apps" "$expected_apps" >"$apps_not_in_casks" || true

arch="$(uname -m)"
: >"$rosetta_leftovers"
: >"$legacy_formulae"
: >"$legacy_casks"
if [[ "$arch" == "arm64" ]]; then
  for path in /usr/local/Homebrew /usr/local/Cellar /usr/local/Caskroom /usr/local/bin/brew; do
    if [[ -e "$path" ]]; then
      echo "$path" >>"$rosetta_leftovers"
    fi
  done

  if [[ -x /usr/local/bin/brew ]]; then
    /usr/local/bin/brew list --formula --full-name 2>/dev/null | sort -u >"$legacy_formulae" || true
    /usr/local/bin/brew list --cask --full-name 2>/dev/null | sort -u >"$legacy_casks" || true
  fi
fi

count_lines() {
  if [[ -s "$1" ]]; then
    wc -l <"$1" | tr -d ' '
  else
    echo 0
  fi
}

apps_not_in_casks_count="$(count_lines "$apps_not_in_casks")"
missing_casks_count="$(count_lines "$missing_casks")"
rosetta_paths_count="$(count_lines "$rosetta_leftovers")"
legacy_formulae_count="$(count_lines "$legacy_formulae")"
legacy_casks_count="$(count_lines "$legacy_casks")"

echo
echo "== Turing App Drift Audit =="
echo "Repo: $REPO_DIR"
echo "Host: $HOST_NAME"
echo "Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo
echo "[1/3] /Applications bundles not represented by declared casks: $apps_not_in_casks_count"
if [[ "$apps_not_in_casks_count" -gt 0 ]]; then
  sed 's/^/  - /' "$apps_not_in_casks"
else
  echo "  none"
fi
echo
echo "[2/3] Declared casks not installed: $missing_casks_count"
if [[ "$missing_casks_count" -gt 0 ]]; then
  sed 's/^/  - /' "$missing_casks"
else
  echo "  none"
fi
echo
echo "[3/3] Rosetta /usr/local Homebrew leftovers"
if [[ "$arch" != "arm64" ]]; then
  echo "  skipped (architecture is $arch)"
else
  echo "  paths present: $rosetta_paths_count"
  if [[ "$rosetta_paths_count" -gt 0 ]]; then
    sed 's/^/    - /' "$rosetta_leftovers"
  fi
  echo "  legacy formulae: $legacy_formulae_count"
  if [[ "$legacy_formulae_count" -gt 0 ]]; then
    sed 's/^/    - /' "$legacy_formulae"
  fi
  echo "  legacy casks: $legacy_casks_count"
  if [[ "$legacy_casks_count" -gt 0 ]]; then
    sed 's/^/    - /' "$legacy_casks"
  fi
fi

if [[ "$apps_not_in_casks_count" -eq 0 \
  && "$missing_casks_count" -eq 0 \
  && "$rosetta_paths_count" -eq 0 \
  && "$legacy_formulae_count" -eq 0 \
  && "$legacy_casks_count" -eq 0 ]]; then
  echo
  echo "Result: no drift detected."
  exit 0
fi

echo
echo "Result: drift detected."
exit 1
