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

The active boot profile is set via `shrikeProfile` in `flake.nix`. Three profiles are always available as specialisations in the boot menu regardless of the default.

| Feature                    | tenfoot | desktop | gaming |
|----------------------------|:-------:|:-------:|:------:|
| Plasma                     |         | ✓       | ✓      |
| Gamescope session (greetd) | ✓       |         |        |
| Sunshine                   |         | ✓       |        |
| Docker                     | ✓       | ✓       |        |
| display-sync               |         | ✓       |        |
| Steam autostart            |         | ✓       | ✓      |

These conditions are evaluated at build time via `activeProfile` in `hosts/shrike/base/`. Changing the default profile in `flake.nix` does not affect the specialisations.

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
