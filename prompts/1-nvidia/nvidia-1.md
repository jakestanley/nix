You are operating against a single-host NixOS 26.05 unstable system named "shrike".

This system is declarative. The Git repository is canonical.
Changes must be made via the repository and deployed using ./deploy-nixos.sh.

Context:

- Non-flake NixOS configuration (classic mode).
- Git repo under ~/git/github.com/jakestanley/nixos-shrike.
- /etc/nixos is a deployment target only.
- Currently only two modules exist:
    - configuration.nix
    - autologin.nix
- Plasma 6 on Wayland.
- greetd with autologin to user "jake".
- SDDM disabled.
- SSH key-only authentication enabled.
- Auto-suspend disabled via services.logind.settings.Login.
- Secure Boot currently disabled but WILL be enabled later.
- Deploy workflow: edit repo → ./deploy-nixos.sh → test → commit.

Architectural Rule:

New features MUST be implemented as separate Nix modules and imported into configuration.nix.
Do NOT append large feature blocks directly into configuration.nix.

For Nvidia:
- Create a new module file (e.g., nvidia.nix).
- Add it via imports in configuration.nix.
- Keep the module minimal and self-contained.
- All Nvidia-related configuration must live inside nvidia.nix.

You ARE allowed to:
- Inspect system state.
- Propose declarative Nix changes.
- Create new module files.
- Modify imports in configuration.nix.
- Commit changes.
- Run ./deploy-nixos.sh.
- Reboot if required.

You are NOT allowed to:
- Edit files directly under /etc outside deployment.
- Run imperative fixes (systemctl enable/disable, manual modprobe, editing /etc files).
- Install packages outside Nix.
- Create manual systemd overrides.
- Introduce stateful drift.
- Scatter Nvidia config across multiple unrelated files.

All modifications must be:
- Declarative.
- Minimal.
- Isolated in a dedicated module.
- Committed before deployment.

Primary Goal (Phase 1):
Enable proprietary Nvidia drivers for Plasma 6 Wayland under greetd autologin.

Secondary Goal (Phase 2, not yet):
Make the Nvidia setup compatible with enabling Secure Boot later.
That means: avoid choices that paint us into a corner. Do NOT implement Secure Boot yet.

Constraints:

- Preserve SSH access at all times.
- Do not break greetd/autologin.
- Do not silently fall back to X11.
- Keep configuration minimal and readable.
- Do not introduce flakes.
- Do not modify unrelated modules.
- Prefer approaches compatible with later Secure Boot enablement.

Procedure:

1. Inspect GPU and driver state.
2. Determine minimal required NixOS options.
3. Create nvidia.nix with Phase 1 configuration only.
4. Import nvidia.nix into configuration.nix.
5. Commit.
6. Deploy.
7. Verify:
   - Wayland active.
   - Nvidia modules loaded.
   - nouveau not loaded.
   - Plasma stable.
   - SSH accessible.
8. If failure:
   - Reboot into previous generation.
   - Adjust only nvidia.nix.
   - Repeat.

Never guess. Always verify.

Proceed with Phase 1.