# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Multi-host NixOS and nix-darwin configuration managing four machines:

- **shrike** — gaming/living room PC (x86_64-linux), KDE Plasma, NVIDIA, Docker, Lanzaboote Secure Boot
- **kestrel** — work PC on shared hardware with shrike (x86_64-linux), Sway, LUKS-encrypted `/home/work`, Lanzaboote Secure Boot
- **adler** — home server (x86_64-linux), ZFS, homelab services (DNS, Nginx, Plex, Samba, OpenVPN)
- **turing** — MacBook (aarch64-darwin), nix-darwin

## Build and Deploy Commands

### Validate (must run on x86_64-linux — adler uses IFD)
```bash
nix flake check
```

### NixOS hosts (shrike / kestrel)
```bash
# Local rebuild
sudo nixos-rebuild switch --flake .#shrike
sudo nixos-rebuild test --flake .#shrike   # activates without setting boot default

# Remote deploy
nixos-rebuild switch --flake .#shrike --target-host shrike.stanley.arpa
nixos-rebuild switch --flake .#kestrel --target-host shrike.stanley.arpa
```

> **Deploy kestrel before shrike.** systemd-boot defaults to the highest generation. Deploying shrike last keeps it as the default boot entry.

### adler (use screen to survive SSH disconnects)
```bash
screen -S deploy-adler bash -lc 'sudo nixos-rebuild switch --flake .#adler -L'
```

### turing (nix-darwin)
```bash
darwin-rebuild switch --flake .#turing
```

### Home Manager standalone (turing/adler without system config)
```bash
home-manager switch --flake .#turing
home-manager switch --flake .#adler
```

### Update flake inputs
```bash
nix flake update
```

### Validate main branch pins
```bash
./scripts/check-main-branch-pins.sh
```

## Architecture

### Flake outputs
- `nixosConfigurations` — shrike, kestrel, adler
- `darwinConfigurations` — turing
- `homeConfigurations` — standalone Home Manager for turing and adler
- `nixosModules.sleepOnLan` — exported module for external reuse
- `overlays.default` — adds `sleep-on-lan` package

### Directory layout
- `hosts/<name>/` — Machine-specific system config: bootloader, kernel, hardware, services, firewall
- `home/jake/common/` — Shared user config across all Unix platforms (shell, git, CLI tools, editor)
- `home/jake/platforms/` — Thin Darwin vs Linux differences
- `home/jake/hosts/` — Host-specific user config (display, GUI apps, Plasma/Sway settings)
- `modules/nixos/` — Reusable NixOS system modules (`base.nix`, `nvidia.nix`, `ssh.nix`, `identities.nix`)
- `modules/shared/` — Cross-target values (e.g. editor env vars)
- `pkgs/` — Custom Nix packages
- `tests/` — NixOS VM tests for DNS and Nginx

### Key design patterns

**Home Manager entry point** — `home/jake/home.nix` conditionally imports `home/jake/hosts/${hostname}.nix` if it exists, then imports platform and common modules.

**Shared boot partition** — shrike and kestrel share `/boot` as separate Lanzaboote entries. Each has its own signing keys under `/var/lib/sbctl`. Recovery requires UEFI setup mode.

**IFD restriction** — `hosts/adler/homelab/registry.nix` uses `pkgs.runCommandLocal` at eval time. `nix flake check` and adler builds must run on x86_64-linux, not on turing (aarch64-darwin).

**Cross-host SSH keys** — `modules/nixos/identities.nix` centralises public keys for jake@turing, jake@shrike, jake@adler used across host `authorized_keys`.

### Service development flow

1. Make changes upstream in the service repo first.
2. Create a branch in this repo; pin the upstream branch/commit.
3. Test with `sudo nixos-rebuild test --flake .#shrike -L`.
4. Verify with `systemctl status <unit>` and `journalctl -u <unit> -f`.
5. Once satisfied, switch and merge. **Do not pin a non-`main` dependency on this repo's `main` branch.**

## CI

Woodpecker CI (`.woodpecker/ci.yaml`) runs:
- `nix flake check` on every push
- `./scripts/check-main-branch-pins.sh` on push/manual trigger to enforce pinned main-branch dependencies
