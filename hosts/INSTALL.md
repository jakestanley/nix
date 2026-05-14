# Installing NixOS

This is intended for Shrike, Kestrel and later Adler

# Preparation

- Download [nixOS Unstable Graphical ISO](https://channels.nixos.org/nixos-unstable/latest-nixos-graphical-x86_64-linux.iso)
- Burn it to a USB

# Partition labelling

`hardware-configuration.nix` uses `/dev/disk/by-label/` for all mounts. When formatting partitions, use the correct labels or the system will not boot:

| Mount | Label |
|-------|-------|
| `/` | `nixos-root` |
| `/boot` | `LINUXBOOT` |

Example:
```bash
mkfs.ext4 -L nixos-root /dev/nvme?n1p3
```

Never reference partitions by UUID (changes on reformat) or device path (NVMe enumeration is unstable).

# Installation

- Burn to USB, disable Secure Boot, boot the installer
- Select the non-LTS kernel option
- Log in with password `nixos`

Mount the partitions, then install:

```bash
nixos-install --flake github:jakestanley/nix#<host> --no-root-passwd
```

> **Branches:** To install from a branch other than `main`, use `github:jakestanley/nix/<branch>#<host>`. The branch must be pushed to GitHub before it can be used here.

# After nixos-install

`nixos-install` does not set passwords. Before rebooting, set them:

```bash
nixos-enter --root /mnt
passwd          # root
passwd jake     # user
# directories for home manager
mkdir -p /nix/var/nix/profiles/per-user/jake
chown jake:jake /nix/var/nix/profiles/per-user/jake
chown -R jake:jake /home/jake/.local
exit
```
