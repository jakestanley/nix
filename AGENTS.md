# AGENTS.md

This repository defines the entire system configuration for host `shrike`.

It is a single-host, flake-based NixOS configuration.

System configuration is declarative. Mutable runtime state may exist under managed paths such as `/var/lib/*`.
There is no manual configuration.

---

## Canonical Workflow

- All changes happen in this repository.
- Do not treat `/etc/nixos` as the canonical source of truth.
- Deploy via `./scripts/deploy-shrike.sh`.
- Rebuild via `sudo nixos-rebuild switch --flake .#shrike`.
- Never edit `/etc/nixos` directly.

If a change is not committed, it does not exist.

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
