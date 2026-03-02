# Requirements

- Secure boot
- Rollback

# Steps

- Download [nixOS Unstable Graphical ISO](https://channels.nixos.org/nixos-unstable/latest-nixos-graphical-x86_64-linux.iso)
- Burn it to a USB
- Remove dummy plug
- Disable Secure Boot
- Boot into installer
- Select option `Installer Plasma (Linux 6.19.3)` (or whatever the non-LTS version is)
- Log in to the installer with the password `nixos`

# Tips
- Reload Plasma with `pkill plasmashell && kstart5 plasmashell`

# Flake workflow
- Normal deploy: `./deploy.sh`
- Update `nixpkgs`: change the pinned revision in `flake.nix`, then run `./deploy.sh --update`
- Future release upgrade: change `nixpkgs.url` in `flake.nix` to the target branch or revision, run `nix flake update`, then run `./deploy.sh`
