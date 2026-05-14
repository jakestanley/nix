{ ... }:

{
  imports = [ ../common/wm.nix ];

  home.homeDirectory = "/home/work";

  wayland.windowManager.sway.config.output = {
    # ASUS VG27B supports 144Hz — default negotiates 60Hz
    "DP-1".mode = "2560x1440@144Hz";
  };

  # home-manager-jake.service runs at boot before LUKS mounts /home/work.
  # Restart it now that the session is live and the directory is accessible.
  wayland.windowManager.sway.config.startup = [
    { command = "systemctl restart home-manager-jake.service"; }
  ];
}
