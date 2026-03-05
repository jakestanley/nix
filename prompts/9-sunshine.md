Context: I have a NixOS system with an Nvidia GPU and Home Manager. I want to configure Sunshine for low-latency in-home streaming. I am using flakes.
Task: Configure Sunshine for low-latency in-home streaming optimised for minimum latency first, quality second. Specifically:

Explore the repo first. Look at the existing structure before making any changes — find where NixOS modules, Home Manager config, and hardware configuration live. Follow existing patterns for how modules are split and imported.
NixOS system config — add or modify as needed:

Enable services.sunshine with autoStart, capSysAdmin, and openFirewall
Enable hardware.nvidia.modesetting.enable = true
Enable hardware.nvidia.nvidiaSettings = true
Disable power management (hardware.nvidia.powerManagement.enable = false)
Add a systemd service to set Nvidia persistence mode on boot via nvidia-smi --persistence-mode=1
Ensure services.xserver.videoDrivers = [ "nvidia" ] is set (or note if Wayland is in use and handle accordingly)

Sunshine will NOT be enabled in gaming mode specification.

Home Manager config — add or modify as needed:

Write ~/.config/sunshine/sunshine.conf via home.file with these settings as a starting point:

encoder = nvenc
nvenc_preset = 1 (fastest/lowest latency)
capture = nvfbc
min_fps_factor = 1
hevc_mode = 0 (H.264 for lowest decode latency)
qp = 28 (reasonable starting quality)
bitrate = 50000 (50 Mbps, tune to network)


Write a minimal ~/.config/sunshine/apps.json via home.file with a default Steam entry and a desktop entry


Do not:

Hardcode usernames — infer from existing config or use variables already present in the repo
Overwrite hardware configuration that already exists without flagging it
Put secrets or credentials in the Nix store
Introduce a new module pattern if the repo already has an established one — follow what's there


After making changes, summarise:

What files were modified and why
Anything that must be done manually (e.g. setting web UI credentials on first launch)
Any assumptions made about the repo structure that should be verified