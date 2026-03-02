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

# Display sync
- Shrike runs a `systemd --user` `display-sync` service in Plasma that disables any `HDMI-*` outputs when any enabled `DP-*` output is present, and re-enables `HDMI-*` outputs when no `DP-*` output is enabled.
- `kscreen-doctor` is installed via `pkgs.kdePackages.libkscreen`.
- To test `kscreen-doctor -o` over SSH, export the Plasma session environment first:

```sh
export XDG_RUNTIME_DIR=/run/user/1000
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
export WAYLAND_DISPLAY=wayland-0
kscreen-doctor -o
```

- If your user is not UID `1000`, substitute the correct UID in the paths above.
- If `wayland-0` does not exist, check available sockets with `ls /run/user/1000/wayland-*`.

# Flake workflow
- Normal deploy: `./scripts/deploy-shrike.sh`
- Test rebuild without switching: `./scripts/deploy-shrike.sh --test`
- Update inputs explicitly with `nix flake update`, then deploy with `./scripts/deploy-shrike.sh`
