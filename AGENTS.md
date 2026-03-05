# AGENTS.md

This repository defines the entire system configuration for host `shrike`.

It is a single-host, flake-based NixOS configuration.

System configuration is declarative. Mutable runtime state may exist under managed paths such as `/var/lib/*`.
There is no manual configuration.

---

## Canonical Workflow

- All changes happen in this repository.
- Scope boundary: do not modify sibling repositories unless explicitly requested for cross-repo work in the current turn.
- Before editing or committing, verify target context with:
  - `pwd`
  - `git rev-parse --show-toplevel`
  - `git branch --show-current`
- Do not commit or push unless explicitly requested in the current turn.
- Do not commit on repo/branch confusion. If there is any ambiguity, stop and ask for confirmation before editing or staging anything.
- Do not treat `/etc/nixos` as the canonical source of truth.
- Deploy via `./scripts/deploy-shrike.sh`.
- Rebuild via `sudo nixos-rebuild switch --flake .#shrike`.
- Never edit `/etc/nixos` directly.

If a change is not committed, it does not exist.

---

## Branch Discipline

- One feature per branch. Each branch delivers exactly one coherent change.
- Derive the scope of work from the branch name before starting. If the name is ambiguous, ask before editing anything.
- Do not commit unrelated changes on a feature branch. Note them in `agent-notes/` for a future branch.
- A branch is ready to merge only when all items in the Merge Checklist below are satisfied. Present the checklist to the user before proposing a merge.

---

## System Model

- NixOS unstable
- Plasma 6
- Wayland only
- No display manager (SDDM disabled)
- TTY autologin launches Plasma
- SSH key-only authentication
- Password SSH disabled
- Git + vim installed system-wide
- zsh as user shell

---

## Strict Rules

1. No `systemctl enable` outside Nix.
2. No manual unit overrides in `/etc/systemd`.
3. No installing packages outside Nix.
4. No editing files in `/etc` directly.
5. No imperative fixes.
6. No ad-hoc hacks to “just make it work”.

If something requires a manual fix, it must be encoded declaratively.

---

## Upstream Change Policy

- Default behavior: do not patch around upstream defects locally.
- Prefer requesting the required fix in the upstream service repository.
- Use local patching only when explicitly requested by Jake Stanley for a temporary unblocker.
- When a temporary local patch is approved, record the upstream issue/PR reference in `agent-notes/<branch-name>.md`.

---

## Adding Software

Permanent software:
- Add to `environment.systemPackages`.

Experimental software:
- Use `nix shell`.
- Do not bloat base config.

---

## SSH

- All authorized keys must be declared in config.
- Password authentication remains disabled.
- Remote access must survive rebuild.

---

## Power Management

- Auto-suspend disabled via `services.logind.settings.Login`.
- No desktop-level power hacks.

---

## Display Stack

- Wayland only.
- If Wayland breaks, fix config.
- Do not fall back to X11 silently.

---

## Recovery

If system fails:

1. Reboot.
2. Select previous generation in systemd-boot.
3. Fix configuration in repo.
4. Deploy again.

Never patch a running system to recover.

---

## Design Constraint

The machine must be fully rebuildable from:

1. Clean NixOS install
2. Cloned repository
3. `./scripts/deploy-shrike.sh`

If that does not work, the configuration is incorrect.

## Source Pinning

- Any external source used by Nix evaluation or NixOS modules must be pinned to an immutable revision.
- Do not fetch moving targets such as Git `HEAD`, unpinned branches, or unpinned tags from Nix code.
- Do not make `nixos-rebuild` depend on whatever upstream happens to contain at evaluation time.
- Updates to external sources must be explicit, reviewable, and committed in this repo.
- If data must come from another repo, pin that repo to a specific commit and update the pin deliberately.
- For private service repos, prefer fetching a pinned upstream commit from Nix over vendoring the full app source into this repository when the build host has read-only credentials.
- Vendoring full upstream service repos into this repository is an exception path, not the default.

## Heavy Runtime Exceptions

- Source-built heavyweight runtimes are still the preferred architecture when practical, ideally backed by a binary cache such as Cachix.
- Binary-wheel or other reduced-purity runtime compromises are exception paths only.
- Do not introduce or extend wheel/binary-runtime exceptions for additional services without Jake Stanley's explicit decision.
- If a temporary exception is approved, document it in an ADR and treat it as a short-term workaround rather than the new default.

## Remote Access Policy (SSH)

Agents may SSH into `shrike` to **inspect** state only.

Allowed over SSH (read-only):
- `cat`, `ls`, `find`, `readlink`, `stat`, `tree`
- `grep`, `sed -n`, `awk` when not writing files
- `journalctl`, `dmesg`, `systemctl status`, `systemctl cat`, `systemctl list-*`
- `nixos-version`, `nixos-option`, `nixos-rebuild dry-run`, `nix eval`, `nix show-derivation`
- `ip`, `ss`, `nmcli` (query only), `mount`, `findmnt`, `lsblk`, `btrfs subvolume list`, `efibootmgr` (read-only)
- `git status`, `git diff`, `git log`

Forbidden over SSH (must be done via repo + deploy only):
- Any command that **modifies state**, including but not limited to:
  - `sudo` (except for read-only commands that require root permissions)
  - `dnf`, `rpm`, `flatpak`
  - `nixos-rebuild switch`, `nixos-rebuild boot`, `nix-env`
  - `systemctl enable/disable/start/stop/restart`
  - Writing/editing files (`tee`, `>`, `>>`, `sed -i`, `cp`, `mv`, `rm`, `chmod`, `chown`, `mkdir`)
  - `btrfs subvolume delete/create`, `snapper`, `efibootmgr` writes

Enforcement:
- If an agent needs to change something, it must:
  1. Propose a Nix change (diff) in this repo.
  2. Have the human run `./scripts/deploy-shrike.sh`.
- If a command might be mutating, treat it as forbidden.

## Agent Notes

- `agent-notes/` is for timestamped investigation and handoff notes between agents.
- These notes are context only, must stay uncommitted, and are ignored via `.gitignore`.
- Maintain one file per branch: `agent-notes/<branch-name>.md`.

Each branch notes file must contain:

**Feature goal** — a short plain-English description of what this branch accomplishes and what "done" looks like.

**Progress log** — append a timestamped entry each session covering: what changed and why, decisions made (including rejected approaches), and any open questions.

Example entry:
```
2025-03-05 — Added wireguard module under modules/vpn/wireguard.nix.
Rejected inline config.nix assignment; kept as a service module for consistency.
Open: confirm peer pubkey with user before finalising.
```

---

## Flake Hygiene

- Do not add a new flake input unless it is strictly necessary for the current feature.
- Do not duplicate an input already satisfiable from existing entries in `flake.nix`.
- Do not add overlays that re-export packages already available from `nixpkgs`.
- If you add an input, document the reason in the branch progress log.

---

## Merge Checklist

Do not propose a merge until every item is confirmed. Present this list to the user.

- [ ] All flake inputs point to a release tag or immutable revision — not a branch or `HEAD`.
- [ ] No custom or forked inputs are pinned to a non-release commit.
- [ ] No `builtins.fetchGit`, `builtins.fetchTarball`, or `fetchFromGitHub` referencing a moving target.
- [ ] `nix flake check` passes without errors.
- [ ] No unrelated changes are included on this branch.
- [ ] Feature goal in `agent-notes/<branch-name>.md` is marked complete and progress log is current.
- [ ] Any approved unfree/impure exceptions are recorded in the progress log and in an ADR.
