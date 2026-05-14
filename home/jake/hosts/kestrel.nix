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
    };
  };
}
