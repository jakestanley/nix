You are operating against a single-host NixOS 26.05 unstable system named "shrike".

This system is declarative. The Git repository is canonical.
Changes must be made in the repository and deployed using ./deploy-nixos.sh.

Environment Context:

- Non-flake NixOS configuration.
- Git repo: ~/git/github.com/jakestanley/nixos-shrike
- /etc/nixos is deployment output only.
- Plasma 6 on Wayland.
- greetd with autologin for user "jake".
- SDDM disabled.
- SSH key-only authentication working.
- Auto-suspend disabled via services.logind.settings.Login.
- Secure Boot currently disabled, but WILL be enabled later.
- GPU: RTX 3070 Ti (GA104), single GPU system.
- Currently running on nouveau.
- No Nvidia configuration present in repo.

Architectural Rule:

All new features must be isolated in their own module.
Do NOT append Nvidia configuration directly into configuration.nix.

For this task:
- Create a new file: nvidia.nix
- Add it to imports in configuration.nix
- All Nvidia-related configuration must live inside nvidia.nix

Primary Goal (Phase 1):

Switch from nouveau to proprietary Nvidia driver for Plasma 6 Wayland.

Requirements:

- Single GPU setup (no PRIME).
- Proprietary driver (not open kernel module).
- Explicit DRM modesetting enabled.
- No experimental options.
- No power management tweaks.
- No PRIME.
- No GSP changes.
- No kernel package overrides.
- No manual kernel params.
- No imperative commands.
- Keep configuration minimal.

Secure Boot Awareness (Phase 2, NOT IMPLEMENTED YET):

- Do not introduce hacks that will block future Secure Boot module signing.
- Do not implement Secure Boot now.
- Do not add lanzaboote or sbctl yet.

Procedure:

1. Verify no existing Nvidia config exists in repo.
2. Create nvidia.nix containing only minimal required configuration.
3. Modify configuration.nix to import ./nvidia.nix.
4. Commit changes with message:
   "nvidia: enable proprietary driver for wayland (phase 1)"
5. Deploy via ./deploy-nixos.sh.
6. Reboot if required.
7. After reboot, verify:
   - lsmod shows nvidia, nvidia_drm, nvidia_modeset
   - nouveau is NOT loaded
   - XDG_SESSION_TYPE=wayland
   - kwin_wayland is active
   - SSH remains accessible
   - journalctl -b contains no Nvidia fatal errors

If boot fails:
- Reboot into previous generation via bootloader.
- Do NOT attempt imperative fixes.
- Adjust only nvidia.nix.
- Redeploy.

Never scatter Nvidia options across multiple files.
Never modify /etc directly.
Never use systemctl enable/disable.

Proceed with Phase 1 implementation now.