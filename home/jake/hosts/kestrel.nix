{ ... }:

{
  imports = [ ../common/wm.nix ];

  home.homeDirectory = "/home/work";

  # home-manager-jake.service runs at boot before LUKS mounts /home/work.
  # Restart it now that the session is live and the directory is accessible.
  wayland.windowManager.sway.config.startup = [
    { command = "systemctl restart home-manager-jake.service"; }
  ];
}
