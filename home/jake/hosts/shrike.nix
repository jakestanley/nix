{ config, inputs, lib, pkgs, ... }:

let
  qfont = import "${inputs.plasma-manager}/lib/qfont.nix" { inherit lib; };
  ubuntuMono13NoAA = qfont.fontToString {
    family = "Ubuntu Mono";
    pointSize = 13;
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
      "katerc"."KTextEditor Renderer"."Text Font" = ubuntuMono13NoAA;
      "konsolerc"."Desktop Entry"."DefaultProfile" = "${konsoleProfileName}.profile";
    };
  };

  xdg.dataFile."konsole/${konsoleProfileName}.profile".text = lib.generators.toINI { } {
    General = {
      Name = konsoleProfileName;
      Parent = "FALLBACK/";
    };
    Appearance = {
      Font = ubuntuMono13NoAA;
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
