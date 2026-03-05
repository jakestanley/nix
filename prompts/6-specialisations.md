You are working in my NixOS config repo on my Mac:

- Repo path (on Mac): /Users/jake/git/github.com/jakestanley/nixos-shrike
- Host: shrike.stanley.arpa
- NixOS is flake-based already.
- Current layout:
  - hosts/shrike/default.nix is the host entrypoint
  - modules/nixos/*.nix are reusable system modules
  - home/jake/* exists (home-manager is set up already)
- Desktop: Plasma 6 on Wayland with greetd autologin (no SDDM)
- Nvidia is already working. Do not break it.
- I want a clean, standard NixOS approach.

Goal
1. Install and enable Docker on the default system config (“everything” mode).
2. Add exactly ONE alternate boot entry called “gaming” that disables Docker (and anything CUDA/workloads related if present), while keeping the desktop usable.
   - I want ONLY two boot options:
     - Default: everything (includes docker)
     - Gaming: no docker (and no cuda/workloads if those exist)
3. This must be implemented using NixOS specialisation (not custom grub entries, not manual systemd target hacking).

Constraints
- Keep the change minimal and modular.
- Prefer putting Docker config in a dedicated module: modules/nixos/docker.nix
- Prefer putting the specialisation overlay wiring in hosts/shrike/default.nix (or a small module if cleaner).
- Do not touch the Nvidia module except if absolutely required (it shouldn’t be).
- Do not introduce flakes refactors or directory refactors. This is a small feature change.
- Ensure greetd autologin + Plasma Wayland still works in both default and gaming modes.

Implementation details
A) Docker
- Enable docker daemon:
  - virtualisation.docker.enable = true;
- Ensure my user “jake” can run docker without sudo:
  - users.users.jake.extraGroups includes "docker"
  - (be careful not to overwrite existing groups, extend the list)
- Consider enabling docker rootless ONLY if it is clearly better for this setup; otherwise skip it.

B) Specialisation: gaming
- Add one specialisation named "gaming" which:
  - Disables docker: virtualisation.docker.enable = false;
  - Disables any obvious CUDA/ML services if they exist in this repo (search for likely options: ollama, cuda services, containers, etc). If none exist, fine.
  - Keeps graphical boot (do NOT force multi-user.target, I still want the desktop).
- Ensure the boot menu shows both:
  - default system
  - specialisation "gaming"

Verification steps (Codex should add these notes to the PR description)
- After deploy, I can verify docker:
  - systemctl status docker
  - groups | grep docker
  - docker ps (should work without sudo in default mode)
- Verify specialisation exists:
  - bootctl list | grep -i gaming (or confirm it appears in boot menu)
- Verify in gaming mode docker is OFF:
  - systemctl status docker should show inactive/disabled or not present
  - docker ps should fail (expected)

Deliverables
- Implement the Nix changes.
- Provide a short commit message suggestion.
- Provide exact commands I should run on shrike after merging:
  - ./scripts/deploy.sh --test
  - ./scripts/deploy.sh
- Keep changes small and readable.

Now do it.
