{ pkgs, ... }:

{
  home.homeDirectory = "/home/work";

  # Lock screen before sleep using swayidle's logind inhibitor mechanism.
  # Replaces the broken swaylock-on-sleep system service which couldn't
  # reliably connect to the user's Wayland socket.
  services.swayidle = {
    enable = true;
    events = {
      before-sleep = "${pkgs.swaylock}/bin/swaylock -f -c 000000";
    };
  };

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
