# nixos-shrike

Multi-host NixOS and nix-darwin configuration.

## Hosts

- [shrike](hosts/shrike/README.md) — gaming/living room PC (x86_64-linux)
- [kestrel](hosts/kestrel) — work PC (x86_64-linux)
- [adler](hosts/adler/README.md) — home server (x86_64-linux)
- [turing](hosts/turing/README.md) — MacBook (aarch64-darwin)

## Deployment

Update inputs: `nix flake update`, then deploy the relevant host.

> **Note:** `nix flake check` must be run from an `x86_64-linux` machine (e.g. shrike or adler).
> `adler`'s config uses IFD (`pkgs.runCommandLocal`) to parse its service registry at eval time,
> which cannot run on `aarch64-darwin`.

### shrike / kestrel

Both configurations share `/boot` and coexist as separate boot entries. Deploying one does not affect the other's boot entry.

> **Always deploy kestrel before shrike.** systemd-boot defaults to the highest generation number.
> Deploying shrike last ensures it remains the default boot entry.

```bash
# Rebuild and switch locally (run on shrike)
sudo nixos-rebuild switch --flake .#shrike
sudo nixos-rebuild switch --flake .#kestrel

# Deploy remotely
nixos-rebuild switch --flake .#shrike --target-host shrike.stanley.arpa
nixos-rebuild switch --flake .#kestrel --target-host shrike.stanley.arpa

# Test (activates without making it the boot default)
sudo nixos-rebuild test --flake .#shrike
```

### adler

Deploy inside `screen` to survive SSH disconnects:

```bash
screen -S deploy-adler bash -lc 'sudo nixos-rebuild switch --flake .#adler -L'
```

### turing

nix-darwin uses `darwin-rebuild` (exported as a flake package) rather than `nixos-rebuild`.
Select `personal` or `work` to control the Dock profile.

```bash
# personal profile
sudo -H nix --extra-experimental-features "nix-command flakes" \
  run ".#darwin-rebuild" -- switch --flake ".#turing-personal"

# work profile
sudo -H nix --extra-experimental-features "nix-command flakes" \
  run ".#darwin-rebuild" -- switch --flake ".#turing-work"
```

> **Note:** `scripts/switch-turing-dock.sh` previously handled this with a sudoers entry
> allowing passwordless execution of that exact script path. If you restore that workflow,
> add the equivalent sudoers rule for the new command path.

## Installation

- Download [nixOS Unstable Graphical ISO](https://channels.nixos.org/nixos-unstable/latest-nixos-graphical-x86_64-linux.iso)
- Burn to USB, disable Secure Boot, boot the installer
- Select the non-LTS kernel option
- Log in with password `nixos`

## Service development flow

- Make app changes in the upstream service repo first.
- Create a dedicated branch in this repo for the service change.
- Push the upstream branch or commit to test, then update the pinned commit here.
- Do not pin a non-`main` dependency head on this repo's `main`. Test from a branch, then move `main` here back to a pinned commit from dependency `main`.
- Prefer squash merges in dependency repos.
- Rebuild on `shrike` with `sudo nixos-rebuild test --flake .#shrike -L`, then `sudo nixos-rebuild switch --flake .#shrike -L` once satisfied.
- Check the updated service with `systemctl status <unit>` and `journalctl -u <unit> -f`.

## Shared modules

| Module | Description |
|--------|-------------|
| `modules/nixos/nvidia.nix` | NVIDIA driver config (modesetting, persistence, graphics). Used by both shrike and kestrel. |
| `modules/nixos/base.nix` | Common NixOS base settings shared across all Linux hosts. |
| `modules/nixos/ssh.nix` | SSH server config. |

## sleep-on-lan

Reusable NixOS module at `hosts/shrike/base/sleep-on-lan.nix`, also exported as `nixosModules.sleepOnLan`.

```nix
{
  imports = [ inputs.nixos-shrike.nixosModules.sleepOnLan ];

  services.sleepOnLan = {
    enable = true;
    openFirewall = true;
    listeners = [ "UDP:9" "HTTP:8009" ];
  };
}
```
