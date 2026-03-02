{ config, inputs, lib, pkgs, ... }:

let
  qfont = import "${inputs.plasma-manager}/lib/qfont.nix" { inherit lib; };
  kateHack10 = qfont.fontToString {
    family = "Hack";
    pointSize = 10;
  };
  konsoleUbuntuMono10NoAA = qfont.fontToString {
    family = "Ubuntu Mono";
    pointSize = 10;
    styleHint = "monospace";
    fixedPitch = true;
    styleStrategy.antialiasing = "disable";
  };
  konsoleProfileName = "Shrike";
in

{
  home.activation.removeLegacyPlasmaSymlinks = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    for file in \
      "${config.xdg.configHome}/kscreenlockerrc" \
      "${config.xdg.configHome}/powerdevilrc"
    do
      if [ -L "$file" ]; then
        $DRY_RUN_CMD rm $VERBOSE_ARG "$file"
      fi
    done
  '';

  home.packages = [ pkgs."ubuntu-classic" ];

  # networking.firewall.enable = false;

  programs.plasma = {
    enable = true;
    configFile = {
      "kscreenlockerrc"."Daemon"."LockOnResume" = false;
      "powerdevilrc"."AC][Display" = {
        "TurnOffDisplayIdleTimeoutSec" = -1;
        "TurnOffDisplayWhenIdle" = false;
      };
      "powerdevilrc"."AC][SuspendAndShutdown"."AutoSuspendAction" = 0;
      "katerc"."KTextEditor Renderer"."Text Font" = kateHack10;
      "konsolerc"."Desktop Entry"."DefaultProfile" = "${konsoleProfileName}.profile";
    };
  };

  xdg.dataFile."konsole/${konsoleProfileName}.profile".text = lib.generators.toINI { } {
    General = {
      Name = konsoleProfileName;
      Parent = "FALLBACK/";
    };
    Appearance = {
      Font = konsoleUbuntuMono10NoAA;
    };
  };

  xdg.configFile."MangoHud/MangoHud.conf".text = ''
    toggle_hud=F10
    fps
    frametime
    cpu_temp
    gpu_temp
    cpu_load
    gpu_load
  '';
}
