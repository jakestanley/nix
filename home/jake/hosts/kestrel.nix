{ pkgs, ... }:

{
  home.homeDirectory = "/home/work";

  wayland.windowManager.sway = {
    enable = true;
    config = {
      terminal = "${pkgs.alacritty}/bin/alacritty";
      menu = "${pkgs.wofi}/bin/wofi --show run";
      modifier = "Mod4";
      bars = [{
        command = "${pkgs.waybar}/bin/waybar";
      }];
      startup = [
        # home-manager-jake.service runs at boot before fscrypt unlocks /home/work.
        # Restart it now that the session is live and the directory is accessible.
        { command = "systemctl restart home-manager-jake.service"; }
      ];
    };
  };
}
