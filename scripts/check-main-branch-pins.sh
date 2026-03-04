#!/bin/sh
set -eu

matches="$(grep -RIn 'ref = "refs/heads/' flake.nix pkgs modules sources 2>/dev/null || true)"

if [ -z "$matches" ]; then
  exit 0
fi

offending="$(
  printf '%s\n' "$matches" | awk '
    {
      split($0, parts, "ref = \"refs/heads/");
      if (length(parts) < 2) {
        next;
      }

      split(parts[2], rest, "\"");
      branch = rest[1];

      if (branch != "main" && branch != "master") {
        print $0;
      }
    }
  '
)"

if [ -n "$offending" ]; then
  echo "main branch must not pin non-default upstream heads." >&2
  echo "Replace these refs with pinned commits from upstream main/master before merging to main:" >&2
  printf '%s\n' "$offending" >&2
  exit 1
fi
