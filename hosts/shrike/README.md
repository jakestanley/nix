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

## VM management (desktop profile only)

libvirt and Cockpit are enabled in the desktop profile only.

### First-time setup

You may need to log out and back in (or run `newgrp libvirtd`) for the `libvirtd` group to take effect.

### Accessing Cockpit

Cockpit is available at `https://shrike:9090` (or the host IP). The TLS certificate will be self-signed unless a cert is provisioned. Log in with your system credentials.

The **Virtual Machines** section in Cockpit requires the `cockpit-machines` plugin, which is bundled with the `cockpit` package in nixpkgs.

### Creating a Debian VM

1. Open Cockpit → Virtual Machines → Create VM
2. Select "Download an OS" and choose Debian
3. Set disk size, RAM, and CPU count as needed
4. Set network to `default` (NAT via virbr0)
5. Start the VM and open the console to complete installation

Or via CLI:
```sh
virt-install \
  --name debian-dev \
  --ram 2048 \
  --vcpus 2 \
  --disk size=20,format=qcow2 \
  --os-variant debian12 \
  --network network=default \
  --cdrom /path/to/debian.iso \
  --graphics none \
  --console pty,target_type=serial \
  --extra-args 'console=ttyS0,115200n8'
```

### VM autostart

```sh
virsh autostart <vm-name>
```

### Snapshots

```sh
# Create
virsh snapshot-create-as <vm-name> snap-$(date +%Y%m%d) --description "before changes"
# List
virsh snapshot-list <vm-name>
# Revert
virsh snapshot-revert <vm-name> <snapshot-name>
```

### SSH into VMs

VMs use the libvirt default NAT network (`192.168.122.0/24`) and are only reachable from Shrike itself. Use Shrike as a jump host.

Find the active DHCP lease (more reliable than `domifaddr`):
```sh
virsh --connect qemu:///system net-dhcp-leases default
```

Then SSH via jump host:
```sh
ssh -J jake@shrike.stanley.arpa <username>@192.168.122.x
```

### Networking

VMs use libvirt's default NAT network (`virbr0`). Host networking is not modified. VMs have internet access via NAT but are not directly reachable from the LAN — only from the host itself.

## Profiles

The active boot profile is set via `shrikeProfile` in `flake.nix`, which is the canonical source of truth for the current default. Three profiles are always available as specialisations in the boot menu regardless of the default.

| Feature                      | tenfoot  | desktop | gaming |
|------------------------------|:--------:|:-------:|:------:|
| Plasma                       | ✓        | ✓       | ✓      |
| Sunshine                     | manual   | ✓       |        |
| Docker                       | ✓        | ✓       |        |
| display-sync                 |          | ✓       |        |
| Steam autostart              | ✓        | ✓       | ✓      |
| libvirt / Cockpit            |          | ✓       |        |

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
