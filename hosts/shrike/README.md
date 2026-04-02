# shrike

## Manual steps

### Filesystems

```sh
sudo chown jake:users /mnt/games /mnt/data
```

### Steam

Make sure this setting is ENABLED:

Steam Settings -> Interface -> Enable GPU accelerated rendering in web views

## Display sync

Shrike runs a `systemd --user` `display-sync` service in the desktop profile that disables any `HDMI-*` outputs when any enabled `DP-*` output is present, and re-enables `HDMI-*` outputs when no `DP-*` output is enabled.

- `kscreen-doctor` is installed via `pkgs.kdePackages.libkscreen`.
- PowerDevil suspend settings are managed via a literal `powerdevilrc` file in Home Manager because Plasma Manager escaped nested section names incorrectly for this setup.

To test `kscreen-doctor -o` over SSH, export the Plasma session environment first:

```sh
export XDG_RUNTIME_DIR=/run/user/1000
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
export WAYLAND_DISPLAY=wayland-0
kscreen-doctor -o
```

If your user is not UID `1000`, substitute the correct UID in the paths above. If `wayland-0` does not exist, check available sockets with `ls /run/user/1000/wayland-*`.

## Profiles

The active boot profile is set via `shrikeProfile` in `flake.nix`. Three profiles are always available as specialisations in the boot menu regardless of the default. **`desktop` is the current default.**

| Feature                      | tenfoot  | desktop | gaming |
|------------------------------|:--------:|:-------:|:------:|
| Plasma                       | ✓        | ✓       | ✓      |
| Sunshine                     | manual   | ✓       |        |
| Docker                       | ✓        | ✓       |        |
| display-sync                 |          | ✓       |        |
| Steam autostart              | ✓        | ✓       | ✓      |

These conditions are evaluated at build time via `activeProfile` in `hosts/shrike/conditionals/`. Changing the default profile in `flake.nix` does not affect the specialisations.

### desktop / gaming

Sleep and wake work correctly. Big Picture mode and the virtual keyboard work when connected to the TV.

**Caveat:** Plasma's RemoteDesktop security setting must be disabled for the Steam Big Picture virtual keyboard to function. This permission is session-scoped and cannot be persisted across boots via policy.

### tenfoot

Runs Plasma with Steam autolaunching directly into Big Picture mode. Retains Plasma's sleep/wake and display handling while keeping a minimal environment with no desktop applications.

**Note:** Sunshine is installed but does not autostart. Start it manually for remote debugging: `systemctl --user start sunshine`.

### Booting into a specialisation remotely

List available entries (note the generation number changes after each rebuild):

```sh
sudo bootctl list | grep -E " id:"
```

Reboot into a specific entry — the full `.conf` filename is required:

```sh
systemctl reboot --boot-loader-entry=nixos-generation-180-specialisation-desktop.conf
```

## Docker services

### homelab-rtx
Runs as a Docker Compose service, not via NixOS.
```sh
git clone git@github.com:jakestanley/homelab-rtx.git
```

### homelab-ollama
Runs as a Docker Compose service, not via NixOS.
```sh
git clone git@github.com:jakestanley/homelab-ollama.git
```

### homelab-demucs
Runs as a Docker Compose service, not via NixOS.
```sh
git clone git@github.com:jakestanley/homelab-demucs.git
```
Copy `.env.example` to `.env` and set `STORAGE_ROOT=/mnt/data/demucs`. Start with `docker-compose up -d`.
