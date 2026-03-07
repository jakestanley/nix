# Unified Unix Source Of Truth (Brainstorm)

## Goal

Use this repository (`nix`) as the single declarative source of truth for Unix-like systems:
- NixOS hosts (current `shrike`).
- macOS user environments via Home Manager first.
- Linux user environments via Home Manager.

## Design Principles

- One repo, many targets.
- Host config and user config are separate concerns.
- Shared user behavior lives once, platform deltas are thin.
- NixOS host safety invariants stay enforceable in host modules.
- No imperative setup scripts as canonical state.

## Proposed Directory Layout

```text
.
├── flake.nix
├── flake.lock
├── hosts/
│   ├── shrike/
│   │   ├── default.nix
│   │   └── hardware-configuration.nix
│   └── <future-host>/
│       └── default.nix
├── home/
│   └── jake/
│       ├── default.nix
│       ├── common/
│       │   ├── shell.nix
│       │   ├── git.nix
│       │   ├── editor.nix
│       │   └── cli.nix
│       ├── platforms/
│       │   ├── darwin.nix
│       │   └── linux.nix
│       └── hosts/
│           ├── shrike.nix
│           └── <future-host>.nix
├── modules/
│   ├── nixos/
│   │   ├── base.nix
│   │   ├── plasma.nix
│   │   ├── greetd-autologin.nix
│   │   └── ...
│   └── home-manager/
│       ├── base.nix
│       └── profiles/
│           ├── workstation.nix
│           └── minimal.nix
├── pkgs/
├── scripts/
│   ├── deploy-shrike.sh
│   ├── preflight-shrike.sh
│   └── ...
└── docs/
    ├── ARCHITECTURE_DECISION_RECORDS.md
    ├── architecture_decision_records/
    └── unified-unix-layout-brainstorm.md
```

## Separation Of Concerns

### `hosts/`
- Owns machine identity and system role.
- Includes NixOS-only decisions: bootloader, kernel, services, firewall, specialisations.
- Must not own general shell/git behavior unless host-specific.

### `home/jake/common/`
- Owns shared user experience across Unix systems:
  - zsh behavior
  - git settings and aliases
  - editor defaults
  - common CLI tools and dotfiles managed by Home Manager
- Must not contain host-only GUI/power/display settings.

### `home/jake/platforms/`
- Owns platform differences only:
  - home directory path
  - per-platform git difftool
  - Darwin vs Linux package gaps
- Keep very small; no duplicated common logic.

### `home/jake/hosts/`
- Owns host-specific user behavior:
  - `shrike` Plasma details
  - `powerdevilrc`
  - Sunshine app config
  - display-sync service
  - Steam autostart

### `modules/nixos/`
- Reusable NixOS system modules.
- Should be host-agnostic and parameterized where possible.

### `modules/home-manager/` (new)
- Reusable HM modules for composable profiles.
- Keeps `home/jake/default.nix` thin and declarative.

### `scripts/`
- Operational entrypoints only (`deploy`, `preflight`, sync utilities).
- Must not become source-of-truth for desired state.

## Flake Output Shape (Target State)

- `nixosConfigurations.<host>` for NixOS machines.
- `homeConfigurations."jake@darwin"` for macOS HM.
- `homeConfigurations."jake@linux"` for non-NixOS Linux HM.

This allows one repo to drive both full-system (NixOS) and user-only (HM) deployments.

## Migration Order (Low Risk)

1. Extract shared HM logic into `home/jake/common/*`.
2. Keep `home/jake/hosts/shrike.nix` behavior unchanged.
3. Add `homeConfigurations` outputs in `flake.nix`.
4. Validate macOS HM activation from this repo.
5. Retire dotfiles as active source; keep archived/read-only.

## Open Questions

- Whether to add `nix-darwin` later for full macOS system config, or stay HM-only.
- Whether shared secrets hooks should stay local-file based (`*.local`) or move to a secret manager module.
- Naming convention for `homeConfigurations` keys (`jake@macbook`, `jake@darwin`, etc.).
