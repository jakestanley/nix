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
- PowerDevil suspend settings are managed via a literal `powerdevilrc` file in Home Manager because Plasma Manager escaped nested section names incorrectly for this setup.
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
- `shrike` deploy: `./scripts/deploy-shrike.sh` (or `--test`)
- `adler` deploy: `./scripts/deploy-adler.sh` (or `--test`)
- `turing` deploy: `./scripts/deploy-turing.sh`
- Update inputs explicitly with `nix flake update`, then deploy the relevant host script above.

# Host manual steps

## shrike
- No required manual post-deploy steps currently.

## adler

### tailscale
- After first deploy that enables Tailscale, authenticate the node into your tailnet:

```sh
sudo tailscale up
```

- Verify with `tailscale status` and `systemctl status tailscaled docker`.

### TLS certificates
Copy the wildcard cert and CA from the Ubuntu box before first activation:
```bash
# or from wherever they are
scp -r user@ubuntu:/etc/homelab/certs /tmp/certs
sudo mkdir -p /etc/homelab/certs
sudo cp -r /tmp/certs/* /etc/homelab/certs/
sudo chmod 600 /etc/homelab/certs/live/wildcard_stanley_arpa/privkey.pem
```

Alternatively, generate certs using the scripts in [homelab-edge](https://github.com/jakestanley/homelab-edge)

As you should know, if you generate new certs as you'll need to re-add them to client trust stores.

Still having permissions issues? Try checking and fixing them

```
ls -la /etc/homelab/certs/live/wildcard_stanley_arpa/
sudo chmod 640 /etc/homelab/certs/live/wildcard_stanley_arpa/privkey.pem
sudo chown root:nginx /etc/homelab/certs/live/wildcard_stanley_arpa/privkey.pem
sudo systemctl restart nginx
```

### OpenVPN

The PKI files are managed outside of Nix. Copy them from the Ubuntu box before first activation:
```bash
sudo scp -r user@ubuntu:/etc/openvpn /etc/openvpn
```

Ensure correct permissions:
```bash
sudo chmod 600 /etc/openvpn/ca.key
sudo chmod 600 /etc/openvpn/server_YeWnWJLw5SiBcE91.key
sudo chmod 600 /etc/openvpn/tls-crypt.key
```

The client configs and CCD directory are included in the copy. The `ipp.txt` lease file will be created automatically by OpenVPN on first run if it does not exist.

### Plex Media Server

Plex metadata and database are managed outside of Nix. Copy from the Ubuntu box before first activation:
```bash
sudo systemctl stop plexmediaserver
sudo scp -r user@ubuntu:/var/lib/plexmediaserver /var/lib/plexmediaserver
```

Ensure correct ownership:
```bash
sudo chown -R plex:plex /var/lib/plexmediaserver
```

## Docker

Stop all containers before copying:
```bash
sudo docker stop $(sudo docker ps -q)
```

Clean up unused images, containers and volumes to reduce copy size:
```bash
sudo docker system prune -a --volumes
```

Copy Docker data to NixOS partition:
```bash
sudo systemctl stop docker
nohup sudo rsync -av --progress /var/lib/docker/ /mnt/nixos-var-lib/docker/ > /tmp/rsync-docker.log 2>&1 &
```

## Plex Media Server

Stop Plex before copying to avoid in-use file issues:
```bash
sudo systemctl stop plexmediaserver
nohup sudo rsync -av --progress /var/lib/plexmediaserver/ /mnt/nixos-var-lib/plexmediaserver/ > /tmp/rsync-plex.log 2>&1 &
```

Ensure correct ownership after copy:
```bash
sudo chown -R plex:plex /mnt/nixos-var-lib/plexmediaserver
```

Note: media files are on ZFS volumes (`/var/media`, `/var/archive`) and do not need to be copied.

## turing
- No required manual post-deploy steps currently.

# Service development flow
- Make app changes in the upstream service repo first, for example `homelab-ollama` or `homelab-rtx`.
- Create a dedicated branch in this Nix repo for the service change instead of iterating directly on `main`.
- Push the upstream branch or commit you want to test.
- Update the pinned commit in this repo's package definition.
- Do not pin a non-`main` dependency head on this repo's `main` branch. Test branch heads from a branch in this repo, then move `main` here back to a pinned commit from dependency `main`.
- Prefer squash merges in dependency repos so the commit pinned here represents one reviewed, merged change on dependency `main`.
- Rebuild on `shrike` with `./scripts/deploy-shrike.sh --test` for a non-persistent test, then `./scripts/deploy-shrike.sh` once satisfied.
- Check the updated service with `systemctl status <unit>` and `journalctl -u <unit> -f`.
- Only run `./scripts/sync-service-port.sh <service>` when the upstream port mapping in `homelab-infra/registry.yaml` changes.

# homelab-rtx
- The reusable NixOS module lives at `modules/nixos/rtx.nix`.
- The canonical local listen port lives at `sources/service-ports/rtx.nix`.
- To sync that value from `homelab-infra/registry.yaml`, run `./scripts/sync-service-port.sh rtx`.
- This sync is explicit only; normal Nix evaluation and deploys do not read `homelab-infra`.
- Host enablement example:

```nix
{
  imports = [ ../../modules/nixos/rtx.nix ];

  services.rtx.enable = true;

  specialisation.gaming.configuration.services.rtx.enable = lib.mkForce false;
}
```

# homelab-ollama
- The reusable NixOS module lives at `modules/nixos/homelab-ollama.nix`.
- The canonical local listen port lives at `sources/service-ports/ollama.nix`.
- To sync that value from `homelab-infra/registry.yaml`, run `./scripts/sync-service-port.sh ollama`.
- This sync is explicit only; normal Nix evaluation and deploys do not read `homelab-infra`.
- Host enablement example:

```nix
{
  imports = [ ../../modules/nixos/homelab-ollama.nix ];

  services.homelabOllama.enable = true;

  specialisation.gaming.configuration.services.homelabOllama.enable = lib.mkForce false;
}
```

# sleep-on-lan
- The reusable NixOS module lives at `modules/nixos/sleep-on-lan.nix`.
- It renders a JSON config from Nix by default and starts the upstream daemon as a root-owned system service so it can bind `UDP:9` and call `systemctl suspend`.
- Host enablement example:

```nix
{
  imports = [ ../../modules/nixos/sleep-on-lan.nix ];

  services.sleepOnLan = {
    enable = true;
    openFirewall = true;
    listeners = [ "UDP:9" "HTTP:8009" ];
  };
}
```

# homelab-demucs
- The reusable NixOS module lives at `modules/nixos/homelab-demucs.nix`.
- The canonical local listen port lives at `sources/service-ports/demucs.nix`.
- To sync that value from `homelab-infra/registry.yaml`, run `./scripts/sync-service-port.sh demucs`.
- This sync is explicit only; normal Nix evaluation and deploys do not read `homelab-infra`.
- Host enablement example:

```nix
{
  imports = [ ../../modules/nixos/homelab-demucs.nix ];

  services.homelabDemucs.enable = true;

  specialisation.gaming.configuration.services.homelabDemucs.enable = lib.mkForce false;
}
```

# Systemd units and specialisations
- Package long-lived services into the Nix store and declare them with `systemd.services.<name>`, rather than copying unit files into `/etc/systemd/system`.
- Keep mutable runtime state under a managed path such as `/var/lib/<name>` with `StateDirectory=`.
- Enable the service in the default host configuration, then explicitly disable it inside any specialisation that must not run it:

```nix
{
  services.example.enable = true;

  specialisation.gaming.configuration.services.example.enable = lib.mkForce false;
}
```
