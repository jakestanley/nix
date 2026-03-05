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
- Normal deploy: `./scripts/deploy-shrike.sh`
- Test rebuild without switching: `./scripts/deploy-shrike.sh --test`
- Update inputs explicitly with `nix flake update`, then deploy with `./scripts/deploy-shrike.sh`

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

# homelab-arcade
- The reusable NixOS module lives at `modules/nixos/homelab-arcade.nix`.
- The canonical local listen port lives at `sources/service-ports/arcade.nix`.
- To sync that value from `homelab-infra/registry.yaml`, run `./scripts/sync-service-port.sh arcade`.
- This sync is explicit only; normal Nix evaluation and deploys do not read `homelab-infra`.
- The package manages the controller/supervisor only. Actual game installs remain host-managed outside Nix and are referenced via mutable host config at `/etc/arcade/config.yaml`.
- The supervisor runs directly (not under `steam-run`) so host config paths under `/etc/arcade` remain visible at runtime.
- If CS2 needs Steam runtime libraries, set `CS2_EXEC_WRAPPER` (for example `${pkgs.steam-run}/bin/steam-run`) so only the CS2 game process is wrapped.
- First-time host setup:
  - Install game servers outside Nix (for example via Steam/SteamCMD as your normal host user).
  - Set the install paths in `/etc/arcade/config.yaml`:
    - `cs2.cs2_path` should point to the CS2 install directory (or executable path expected by the controller).
    - `sandstorm.sandstorm_path` should point to the Sandstorm install directory (or `InsurgencyServer.exe` path).
  - Set the CS2 RCON password in `/etc/arcade/config.yaml`:
    - `sudoedit /etc/arcade/config.yaml`
    - under `cs2`, set `rcon_password` to a strong value.
  - Keep these paths host-local and mutable; do not put game binaries under the Nix store.
  - Quick checks: `test -e "<cs2 path>"` and `test -e "<sandstorm path or exe>"`.
- After updating `/etc/arcade/config.yaml`, restart only the service: `sudo systemctl restart arcade`.
- Verification after config changes: `sudo journalctl -u arcade -n 80 --no-pager`.
- With `openFirewall = true`, the module opens the arcade portal port plus the common CS2 and Sandstorm game-facing ports (`TCP 27015`, `UDP 27015`, `UDP 27102`, `UDP 27131`).
- Host enablement example:

```nix
{
  imports = [ ../../modules/nixos/homelab-arcade.nix ];

  services.homelabArcade = {
    enable = true;
    createUser = false;
    user = "jake";
    group = "users";
  };
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

- Some services, such as `homelab-arcade`, are intentionally left enabled in `gaming` because they are part of the control plane for those workloads.
