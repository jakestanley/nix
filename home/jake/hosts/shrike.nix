{ config, lib, ... }:

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
