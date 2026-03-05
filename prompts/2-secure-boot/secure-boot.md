You are Codex operating on my NixOS host.

Goal (this task):
Implement Secure Boot support on this NixOS system in a way that remains compatible with the already-working proprietary Nvidia driver on Plasma 6 Wayland with greetd autologin.

Nvidia is working. That must not regress.

We are now moving to Secure Boot.

Do NOT:
- Switch to flakes.
- Change the display stack (keep greetd + autologin + Plasma Wayland).
- Add PRIME or hybrid GPU configuration (this is single-GPU).
- Create a new branch.

Git workflow:
- Stay on the existing `nvidia` branch.
- Make small, clean commits.
- Do NOT create a new branch.
- All changes must live in the repository.
- I will run the deploy script manually after your changes.
- Do NOT edit /etc directly except via the deployment process.

Repository structure:
Currently only:
- configuration.nix
- autologin.nix
- nvidia.nix

You must:
- Create a new module file: secureboot.nix
- Import it in configuration.nix
- Keep all Secure Boot related configuration isolated inside secureboot.nix

Host context:
- Host: shrike.stanley.arpa
- OS: NixOS unstable (26.05 pre)
- Desktop: Plasma 6 on Wayland
- Login: greetd autologin for user jake
- GPU: NVIDIA GA104 RTX 3070 Ti
- Nvidia proprietary driver working
- nouveau not loaded
- Secure Boot currently disabled in firmware
- System boots via UEFI
- SSH working

Rules:
- Begin with read-only investigation.
- Report findings clearly.
- Then propose minimal declarative changes.
- Keep changes minimal and reproducible.
- Prefer lanzaboote if appropriate for unstable.
- Ensure Nvidia continues to function under Secure Boot.
- Avoid hacks that break future rebuild reproducibility.

Investigation checklist (run these first and report findings):

1) Confirm UEFI + boot loader:
   - bootctl status
   - findmnt /boot
   - findmnt /boot/efi
   - lsblk -f
   - grep -R "boot.loader" -n /etc/nixos/*.nix

2) Confirm current Secure Boot state:
   - mokutil --sb-state (if installed)
   - otherwise inspect bootctl output
   - confirm /sys/firmware/efi exists

3) Confirm Nvidia state (baseline before Secure Boot work):
   - lsmod | egrep "nouveau|nvidia"
   - nvidia-smi
   - sudo cat /sys/module/nvidia_drm/parameters/modeset

4) Check whether sbctl or lanzaboote are already present:
   - command -v sbctl || echo "no sbctl"
   - nix search nixpkgs lanzaboote (read-only)

After investigation, produce:

A) Findings summary:
   - Boot mode
   - Boot loader in use
   - ESP mount
   - Current Secure Boot state
   - Nvidia status

B) Minimal implementation plan:
   - Whether to use lanzaboote or sbctl
   - Required NixOS options
   - Whether additional kernel module signing is required for Nvidia

C) Implement:

1. Create secureboot.nix
2. Add only required Secure Boot options
3. Import secureboot.nix in configuration.nix
4. Commit on the existing `nvidia` branch with message:
   "secureboot: add signed boot chain support (phase 1)"

Do NOT:
- Enable Secure Boot in firmware yet.
- Force-enable lockdown until we verify signed chain.
- Modify nvidia.nix unless required for Secure Boot compatibility.

D) After commit, provide:

- Exact rebuild command I should run
- Exact commands to generate/enroll Secure Boot keys
- Exact BIOS/UEFI setting to change
- Exact verification commands after reboot

E) Safety plan:

- How to recover if Secure Boot prevents boot
- How to disable Secure Boot safely
- How to revert to previous NixOS generation

Important constraints:

- Preserve SSH access.
- Preserve Wayland.
- Preserve greetd autologin.
- Preserve Nvidia functionality.
- Keep configuration readable and minimal.
- No flakes.
- No unrelated refactors.

Start with the investigation phase only. Do not implement until you report findings.