You are Codex. Task: migrate this NixOS repo to a standard flake workflow with controlled updates and no rsync to /etc/nixos.

Context

- Host: shrike (NixOS 26.05 pre-release currently)
- Repo path on host: ~/git/github.com/jakestanley/nixos
- Current workflow: rsync repo into /etc/nixos then run nixos-rebuild switch
- Goal: move to a standard flake workflow
- Requirements:
  - Pin to nixos-26.05 branch
  - Only update NixOS when explicitly requested
  - Build directly from repo path
  - No rsync to /etc/nixos
  - Keep greetd, Plasma Wayland, Nvidia config intact
  - Minimal refactor — do not reorganize modules unnecessarily

Non-negotiables

- Must remain SSH-accessible after migration.
- Must support rollback via normal NixOS generation rollback.
- Must not introduce Home Manager or other structural changes.
- Must not change existing modules unless necessary for flakes.

What to implement

1) Add flake.nix
   - Use:
     nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
   - Define:
     nixosConfigurations.shrike = nixpkgs.lib.nixosSystem { ... }
   - system = "x86_64-linux"
   - modules = [ ./configuration.nix ]
   - If configuration.nix imports other files, leave them untouched.

2) Commit flake.lock
   - Run nix flake update once to generate lockfile.
   - Do not auto-update beyond this.

3) Ensure flakes are enabled declaratively
   In configuration.nix, add if missing:

     nix.settings.experimental-features = [ "nix-command" "flakes" ];

4) Update deploy script to this model:

   - No rsync.
   - Must run:
       sudo nixos-rebuild switch --flake "$REPO#shrike"

   - Add optional update mode:
       ./deploy-shrike.sh --update
     should run:
       nix flake lock --update-input nixpkgs
       sudo nixos-rebuild switch --flake "$REPO#shrike"

   - Default behavior: switch only, no update.

   - Refuse to run if:
       - repo has uncommitted changes
       - unless user passes --allow-dirty

5) Provide final usage instructions:

   Normal deploy:
       ./deploy-shrike.sh

   Update nixpkgs (stay on 26.05 branch):
       ./deploy-shrike.sh --update

   Upgrade to next release later:
       - change nixpkgs.url branch in flake.nix
       - run nix flake update
       - run ./deploy-shrike.sh

Validation steps you must perform

Before switching:
    nix flake show
    sudo nixos-rebuild dry-run --flake .#shrike

Only if dry-run succeeds:
    sudo nixos-rebuild switch --flake .#shrike

If failure occurs:
    Do not switch.
    Print clear diagnostics.

Deliverables

- flake.nix
- flake.lock
- updated deploy-shrike.sh
- small README snippet explaining update model
- confirmation that system builds successfully

Begin.
