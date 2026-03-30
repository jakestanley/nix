# nixos-shrike

Multi-host NixOS and nix-darwin configuration.

## Hosts

- [shrike](hosts/shrike/README.md) — gaming/living room PC (x86_64-linux)
- [adler](hosts/adler/README.md) — home server (x86_64-linux)
- [turing](hosts/turing/README.md) — MacBook (aarch64-darwin)

## Flake workflow

- `shrike` deploy: `./scripts/deploy-shrike.sh` (or `--test`)
- `adler` deploy: `./scripts/deploy-adler.sh` (or `--test`)
- `turing` deploy: `./scripts/deploy-turing.sh`
- Update inputs: `nix flake update`, then deploy the relevant host.

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
- Rebuild on `shrike` with `./scripts/deploy-shrike.sh --test`, then `./scripts/deploy-shrike.sh` once satisfied.
- Check the updated service with `systemctl status <unit>` and `journalctl -u <unit> -f`.

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
