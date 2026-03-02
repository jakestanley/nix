{ ... }:

{

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
}
