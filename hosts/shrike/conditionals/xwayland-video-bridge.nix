{ pkgs, activeProfile, ... }:

{
  systemd.user.services.xwayland-video-bridge = {
    enable = activeProfile == "desktop";
    description = "Mirror Wayland compositor output into X11 for Steam screen capture";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.kdePackages.xwaylandvideobridge}/bin/xwaylandvideobridge";
      Restart = "always";
      RestartSec = 3;
    };
  };

  environment.systemPackages = pkgs.lib.optionals (activeProfile == "desktop") [
    pkgs.kdePackages.xwaylandvideobridge
  ];
}
