# shrike

## Manual steps

### First boot after reinstall

After a fresh `nixos-install`, run these steps before considering the system ready:

1. **Activate home-manager** as the user:
   ```sh
   home-manager switch --flake .#jake@shrike
   ```

### Secure Boot

Both shrike and kestrel use Lanzaboote. Signing keys live at `/var/lib/sbctl` on the shared root partition and are lost if the root partition is reformatted.

To recover after a reinstall:

1. Enter UEFI Setup Mode in the BIOS (clear all Secure Boot keys)
2. Generate new keys:
   ```sh
   sudo sbctl create-keys
   ```
3. Rebuild both hosts:
   ```sh
   sudo nixos-rebuild switch --flake .#shrike
   sudo nixos-rebuild boot --flake .#kestrel
   ```
4. Verify all entries are signed:
   ```sh
   sudo sbctl verify
   ```
5. Enrol keys into firmware (includes Microsoft keys for Windows):
   ```sh
   sudo sbctl enroll-keys --microsoft
   ```
6. In ASUS BIOS: set **OS Type → Windows UEFI Mode** and confirm Secure Boot is enabled
7. Reboot — shrike, kestrel, and Windows should all boot

### Filesystems

```sh
sudo chown jake:users /mnt/games /mnt/data
```

### Steam

Make sure this setting is ENABLED:

Steam Settings -> Interface -> Enable GPU accelerated rendering in web views

## Display sync

Shrike runs a `systemd --user` `display-sync` service that disables any `HDMI-*` outputs when any `DP-*` output is enabled, and re-enables `HDMI-*` outputs when no `DP-*` output is enabled.

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

## Booting

Shrike and kestrel share `/boot`. See the root README for deployment order and boot entry selection.

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

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
