You are working on my NixOS repo.

Repo (local): /Users/jake/git/github.com/jakestanley/nixos-shrike
Target host: shrike.stanley.arpa (ssh as jake)
Branch: stay on existing `steam` branch
I will run the deploy script manually.

Goal

Create a reusable “gaming layer” NixOS module that provides:

- Steam (native NixOS Steam)
- 32-bit support required for Proton on Nvidia
- MangoHud installed
- GameMode installed and gamemoded running
- GE-Proton installed declaratively (latest release provided URL)
- MangoHud config for user jake with toggle_hud=F10
- Clean, layered module (gaming.nix) imported from configuration.nix

Do NOT:
- Use flakes
- Use Flatpak Steam
- Use imperative downloads
- Use curl/wget
- Require manual tar extraction
- Add random hacks
- Modify nvidia.nix
- Change greetd or desktop stack

System context

- NixOS unstable (26.05 pre)
- Plasma 6 on Wayland
- greetd autologin
- Nvidia proprietary driver working
- Single GPU
- systemd-boot
- Secure Boot work is paused

GE-Proton requirement

Fetch and install the latest GE-Proton release declaratively:

URL:
https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton10-32/GE-Proton10-32.tar.gz

Requirements:

- Use pkgs.fetchurl with sha256
- Extract via a derivation (stdenv.mkDerivation or similar)
- Install contents to a clean output path
- Symlink that derivation into Steam’s compatibilitytools.d path
- For native Steam this is:

  /home/jake/.steam/root/compatibilitytools.d

If that path does not exist yet:
- Ensure directory is created declaratively
- Ensure ownership jake:jake
- No imperative post-build hacks

Do NOT:
- Download at runtime
- Use home-manager (unless already present in repo)
- Require user to run helper script

Steam + Gaming Requirements

Enable Steam properly for Nvidia + Proton:

- programs.steam.enable = true
- hardware.opengl.driSupport32Bit = true
- Enable required Vulkan/OpenGL 32-bit support
- Keep config minimal

Enable GameMode:

- programs.gamemode.enable = true
- Ensure gamemoded systemd service runs

Install MangoHud:

- Install mangohud package
- Do NOT force-enable globally
- Provide usage instructions for Steam launch options:
  MANGOHUD=1 gamemoderun %command%

Create MangoHud config for jake:

Path:
~/.config/MangoHud/MangoHud.conf

Content must include:

toggle_hud=F10
fps
frametime
cpu_temp
gpu_temp
cpu_load
gpu_load

Keep config minimal and readable.

Implementation Structure

1. Create new module:
   modules/gaming.nix

2. In configuration.nix:
   import ./modules/gaming.nix

3. Keep all gaming-related configuration inside gaming.nix

4. Commit message:
   "gaming: steam + GE-Proton + mangohud + gamemode layer"

Verification commands to provide after implementation

- steam --version
- systemctl status gamemoded
- ls ~/.steam/root/compatibilitytools.d
- ls -l compatibilitytools.d to confirm GE-Proton symlink
- nix-store -q --references /run/current-system | grep proton
- lsmod | grep nvidia
- echo $XDG_SESSION_TYPE

Start by listing planned file changes.
Then implement.
Then provide verification commands.