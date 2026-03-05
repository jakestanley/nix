You are Codex working in my git repo that contains a working flake-based NixOS configuration for my desktop host "shrike".

Context
- Host: shrike.stanley.arpa
- Current system: NixOS, Plasma 6 on Wayland, greetd autologin for user "jake", Nvidia working, SSH working.
- Repo is already migrated to flakes and currently works with:
  sudo nixos-rebuild switch --flake .#shrike
- I want to refactor now into a clean multi-host structure, and set it up so adding Home Manager later is trivial and host-specific overrides are clean.

Primary goal (do now)
Refactor the repo into a “standard” multi-host layout:

- flake.nix, flake.lock
- hosts/<hostname>/default.nix as the host entrypoint
- hosts/<hostname>/hardware-configuration.nix
- modules/nixos/*.nix for reusable NixOS modules
- home/<user>/home.nix for Home Manager user config (create placeholder now, do NOT enable Home Manager yet unless explicitly asked in the plan below)
- home/<user>/hosts/<hostname>.nix for host-specific Home Manager overrides (create placeholder now)
- scripts/deploy-shrike.sh that rebuilds using flakes without rsyncing to /etc/nixos

Hard requirements
- Do not break shrike. After refactor, these must still work:
  - greetd autologin -> Plasma Wayland session for jake
  - Nvidia proprietary driver stack still works, nouveau not loaded
  - OpenSSH still works
- Git workflow: small commits with clear messages.
- Keep secrets out of the repo.
- Keep behaviour the same: only refactor, no “optimisations” or unrelated changes.

Secondary goal (prep now, implement later)
Prepare for Home Manager with host-specific overrides, but do NOT fully enable it yet unless it can be done without changing behaviour. I want the repo structure ready so the next milestone can be:
- add home-manager as a flake input
- enable it for user jake
- start managing zsh history, git config, etc
But this prompt is primarily about the directory refactor and clean wiring.

Preferred layout (use exactly this unless you have a strong reason)
Repo root:
- flake.nix
- flake.lock
- README.md (optional, short)
- scripts/
    deploy-shrike.sh
- hosts/
    shrike/
      default.nix
      hardware-configuration.nix
- modules/
    nixos/
      base.nix
      ssh.nix
      plasma.nix
      greetd-autologin.nix
      nvidia.nix
      (keep module count minimal; only create files that reduce clutter)
- home/
    jake/
      home.nix              (placeholder now)
      hosts/
        shrike.nix          (placeholder now)

Design rules
- hosts/<name>/default.nix should mostly be “wiring”:
  - imports hardware-configuration + modules + any host-specific settings
- modules/nixos/*.nix should be reusable, not host-specific.
- home/* is for Home Manager only. For now keep it minimal and not enabled, but structure must be ready.
- Keep the flake output clean:
  - nixosConfigurations.shrike must point to hosts/shrike/default.nix
  - Avoid putting a ton of config directly in flake.nix.

Deploy script requirements
- No rsync to /etc/nixos.
- From repo root, run:
  sudo nixos-rebuild switch --flake .#shrike
- Add an optional --test mode if easy (nixos-rebuild test).
- Do not auto-update flake.lock. Updates should be explicit via nix flake update.

Execution plan (follow this order)
1) Inspect current repo:
   - Print repo tree
   - Identify current host entry module(s) and imported files (configuration.nix, autologin.nix, etc)
2) Create the new directory structure.
3) Move files into the new structure with minimal changes.
4) Create modules/nixos/*.nix by extracting logical chunks from the current config:
   - base (locale, users, env vars, common packages)
   - ssh (openssh settings + authorized keys if currently in system config)
   - plasma (plasma enablement, wayland session bits that are generic)
   - greetd-autologin (greetd config for autologin user jake)
   - nvidia (all nvidia-specific settings)
   Keep each module readable and minimal.
5) Update flake.nix to point to hosts/shrike/default.nix and import the modules.
6) Add home/jake/home.nix and home/jake/hosts/shrike.nix as placeholders (commented and ready), but do NOT enable Home Manager yet.
7) Add scripts/deploy-shrike.sh and make it executable.
8) Validate:
   - nix flake check (if reasonable)
   - sudo nixos-rebuild test --flake .#shrike
   - then sudo nixos-rebuild switch --flake .#shrike
9) Confirm runtime signals (commands you can run):
   - login path: systemctl status greetd
   - session: echo $XDG_SESSION_TYPE and confirm wayland in an interactive session
   - nvidia: lsmod | grep -E 'nvidia|nouveau'
   - ssh: systemctl status sshd

Output expected
- The full new file tree.
- The updated flake.nix.
- hosts/shrike/default.nix and hardware-configuration.nix in place.
- modules/nixos/*.nix with content.
- home placeholders created as above.
- scripts/deploy-shrike.sh.
- A short note in the PR summary describing what moved where and how to deploy.

Strict avoid list
- Do not introduce lanzaboote or secure boot changes.
- Do not change bootloader, kernel, greetd behaviour, plasma behaviour, or nvidia settings beyond refactoring into modules.
- Do not start managing dotfiles yet beyond creating placeholder home manager files.

Start now by showing the current repo tree and the current flake.nix outputs/modules list, then proceed with step 2.
