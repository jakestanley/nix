{ pkgs, lib, ... }:

let
  # Base16 Monokai — Wimer Hazenberg
  base00 = "#272822";
  base01 = "#383830";
  base02 = "#49483e";
  base03 = "#75715e";
  base05 = "#f8f8f2";
  base07 = "#f9f8f5";
  base08 = "#f92672";
  base0D = "#66d9ef";

  mod = "Mod4";
  playerctl = "${pkgs.playerctl}/bin/playerctl";
in
{
  home.packages = with pkgs; [
    nerd-fonts.ubuntu-mono
  ];

  services.swayidle = {
    enable = true;
    events = {
      before-sleep = "${pkgs.swaylock}/bin/swaylock -f -c 000000";
    };
  };

  programs.waybar = {
    enable = true;
    settings = [{
      layer = "top";
      position = "top";
      modules-left = [ "sway/workspaces" "sway/mode" ];
      modules-center = [ "clock" ];
      modules-right = [ "cpu" "memory" "network" "tray" ];
      "clock".format = "{:%H:%M  %Y-%m-%d}";
      "cpu".format = " {usage}%";
      "memory".format = " {percentage}%";
      "network" = {
        format-ethernet = "󰈀 {ifname}";
        format-disconnected = "󰖪 disconnected";
      };
    }];
    style = ''
      * {
        font-family: "UbuntuMono Nerd Font";
        font-size: 13px;
        border: none;
        border-radius: 0;
        min-height: 0;
      }
      window#waybar {
        background-color: ${base00};
        color: ${base05};
      }
      #workspaces button {
        padding: 0 8px;
        color: ${base05};
        background-color: ${base01};
        border-bottom: 3px solid transparent;
      }
      #workspaces button.focused {
        background-color: ${base02};
        border-bottom: 3px solid ${base0D};
      }
      #workspaces button.urgent {
        background-color: ${base08};
        color: ${base00};
      }
      #clock, #cpu, #memory, #network, #tray {
        padding: 0 10px;
      }
      #clock { color: ${base0D}; }
    '';
  };

  wayland.windowManager.sway = {
    enable = true;
    config = {
      modifier = mod;
      terminal = "${pkgs.alacritty}/bin/alacritty";
      menu = "${pkgs.wofi}/bin/wofi --show run";
      fonts = {
        names = [ "UbuntuMono Nerd Font" ];
        size = 10.0;
      };
      gaps = {
        inner = 8;
        outer = 12;
      };
      window = {
        border = 3;
        titlebar = false;
      };
      floating = {
        border = 3;
        titlebar = false;
      };
      colors = {
        background = base07;
        focused = {
          border = base05;
          background = base0D;
          text = base00;
          indicator = base0D;
          childBorder = base0D;
        };
        focusedInactive = {
          border = base01;
          background = base01;
          text = base05;
          indicator = base03;
          childBorder = base01;
        };
        unfocused = {
          border = base01;
          background = base00;
          text = base05;
          indicator = base01;
          childBorder = base01;
        };
        urgent = {
          border = base08;
          background = base08;
          text = base00;
          indicator = base08;
          childBorder = base08;
        };
        placeholder = {
          border = base00;
          background = base00;
          text = base05;
          indicator = base00;
          childBorder = base00;
        };
      };
      bars = [{
        command = "${pkgs.waybar}/bin/waybar";
      }];
      keybindings = lib.mkOptionDefault {
        # Vim-style focus (supplements arrow keys from defaults)
        "${mod}+j" = "focus left";
        "${mod}+k" = "focus down";
        "${mod}+l" = "focus up";
        "${mod}+semicolon" = "focus right";

        # Move workspace between outputs
        "${mod}+Control+Left" = "move workspace to output left";
        "${mod}+Control+Right" = "move workspace to output right";

        # Sticky floating window (persists across workspaces, e.g. video)
        "${mod}+Shift+s" = "floating enable; sticky enable; resize set 640 480";

        # Media controls
        "${mod}+z" = "exec ${playerctl} previous";
        "${mod}+x" = "exec ${playerctl} play-pause";
        "${mod}+c" = "exec ${playerctl} next";
        "XF86AudioPrev" = "exec ${playerctl} previous";
        "XF86AudioPlay" = "exec ${playerctl} play-pause";
        "XF86AudioNext" = "exec ${playerctl} next";

        # Volume
        "${mod}+Shift+z" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
        "${mod}+Shift+x" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        "${mod}+Shift+c" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
        "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
        "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        "XF86AudioRaiseVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";

        # Named workspaces (override numeric defaults)
        "${mod}+1" = "workspace \"1: term\"";
        "${mod}+2" = "workspace \"2: dev\"";
        "${mod}+3" = "workspace \"3: text\"";
        "${mod}+4" = "workspace \"4: git\"";
        "${mod}+5" = "workspace \"5: aws\"";
        "${mod}+6" = "workspace \"6: web\"";
        "${mod}+7" = "workspace \"7: db\"";
        "${mod}+8" = "workspace \"8: music\"";
        "${mod}+9" = "workspace \"9: comms\"";
        "${mod}+0" = "workspace \"10: misc\"";
        "${mod}+Shift+1" = "move container to workspace \"1: term\"";
        "${mod}+Shift+2" = "move container to workspace \"2: dev\"";
        "${mod}+Shift+3" = "move container to workspace \"3: text\"";
        "${mod}+Shift+4" = "move container to workspace \"4: git\"";
        "${mod}+Shift+5" = "move container to workspace \"5: aws\"";
        "${mod}+Shift+6" = "move container to workspace \"6: web\"";
        "${mod}+Shift+7" = "move container to workspace \"7: db\"";
        "${mod}+Shift+8" = "move container to workspace \"8: music\"";
        "${mod}+Shift+9" = "move container to workspace \"9: comms\"";
        "${mod}+Shift+0" = "move container to workspace \"10: misc\"";
      };
      # Explicit resize mode: 10px coarse (arrow keys), 5px fine (mod+arrow)
      modes = {
        resize = {
          Left = "resize shrink width 10 px or 10 ppt";
          Down = "resize grow height 10 px or 10 ppt";
          Up = "resize shrink height 10 px or 10 ppt";
          Right = "resize grow width 10 px or 10 ppt";
          "${mod}+Left" = "resize shrink width 5 px or 5 ppt";
          "${mod}+Down" = "resize grow height 5 px or 5 ppt";
          "${mod}+Up" = "resize shrink height 5 px or 5 ppt";
          "${mod}+Right" = "resize grow width 5 px or 5 ppt";
          Return = "mode default";
          Escape = "mode default";
        };
      };
    };
  };
}
