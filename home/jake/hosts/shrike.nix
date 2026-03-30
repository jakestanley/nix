{ config, inputs, lib, pkgs, ... }:

let
  qfont = import "${inputs.plasma-manager}/lib/qfont.nix" { inherit lib; };
  kateHack10 = qfont.fontToString {
    family = "Hack";
    pointSize = 10;
  };
  konsoleUbuntuMono = qfont.fontToString {
    family = "Ubuntu Mono";
    pointSize = 11;
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

  home.packages = [
    pkgs."ubuntu-classic"
  ];

  # networking.firewall.enable = false;

  programs.plasma = {
    enable = true;
    session.sessionRestore.restoreOpenApplicationsOnLogin = "startWithEmptySession";
    workspace.colorScheme = "BreezeDark";
    configFile = {
      "kscreenlockerrc"."Daemon"."LockOnResume" = false;
      "katerc"."KTextEditor Renderer"."Text Font" = kateHack10;
      "konsolerc"."Desktop Entry"."DefaultProfile" = "${konsoleProfileName}.profile";
    };
  };

  xdg.configFile."powerdevilrc" = {
    force = true;
    text = ''
      [AC][Display]
      TurnOffDisplayIdleTimeoutSec=-1
      TurnOffDisplayWhenIdle=false

      [AC][SuspendAndShutdown]
      AutoSuspendAction=0
      AutoSuspendIdleTimeoutSec=0
    '';
  };

  xdg.dataFile."konsole/${konsoleProfileName}.profile".text = lib.generators.toINI { } {
    General = {
      Name = konsoleProfileName;
      Parent = "FALLBACK/";
    };
    Appearance = {
      Font = konsoleUbuntuMono;
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

  home.file.".config/sunshine/sunshine.conf".text = ''
    encoder = nvenc
    nvenc_preset = 1
    capture = kms
    origin_web_ui_allowed = lan
    hevc_mode = 0
    qp = 28
  '';

  home.file.".config/sunshine/apps.json".text = builtins.toJSON {
    env = {
      PATH = "$(PATH):/run/current-system/sw/bin:$(HOME)/.local/bin";
    };
    apps = [
      {
        name = "Desktop";
        "image-path" = "desktop.png";
      }
      {
        name = "Steam Big Picture";
        detached = [
          "setsid steam steam://open/bigpicture"
        ];
        "image-path" = "steam.png";
      }
    ];
  };


}
