{ config, lib, inputs, pkgs, ... }:

let
  qfont = import "${inputs.plasma-manager}/lib/qfont.nix" { inherit lib; };
  konsoleUbuntuMono = qfont.fontToString {
    family = "Ubuntu Mono";
    pointSize = 11;
    styleHint = "monospace";
    fixedPitch = true;
    styleStrategy.antialiasing = "disable";
  };
  konsoleProfileName = "Kestrel";
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

  home.homeDirectory = "/home/work";

  programs.plasma = {
    enable = true;
    session.sessionRestore.restoreOpenApplicationsOnLogin = "startWithEmptySession";
    workspace.colorScheme = "BreezeDark";
    configFile = {
      "kscreenlockerrc"."Daemon"."Autolock" = false;
      "kscreenlockerrc"."Daemon"."LockOnResume" = false;
      "konsolerc"."Desktop Entry"."DefaultProfile" = "${konsoleProfileName}.profile";
    };
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
}
