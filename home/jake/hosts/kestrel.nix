{ ... }:

{
  imports = [ ../common/wm.nix ];

  home.homeDirectory = "/home/work";

  wayland.windowManager.sway.config.output = {
    "DP-1" = { mode = "2560x1440@144Hz"; pos = "0 0"; };
    # Centre-aligned to DP-1: (1440-1200)/2 = 120
    "DP-4"  = { pos = "2560 120"; };
  };

  # Dummy plug — disable so it doesn't consume a workspace
  wayland.windowManager.sway.extraConfig = ''
    output "HDMI-A-1" disable
  '';

  # home-manager-jake.service runs at boot before LUKS mounts /home/work.
  # Restart it now that the session is live and the directory is accessible.
  wayland.windowManager.sway.config.startup = [
    { command = "systemctl restart home-manager-jake.service"; }
  ];
}
