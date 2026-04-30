{ pkgs, activeProfile, ... }:

{
  systemd.user.services.steam-autostart = {
    enable = true;
    description = "Start Steam when the graphical session starts";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig.Environment = "PATH=/run/current-system/sw/bin:/usr/bin:/bin";
    serviceConfig.ExecStart = if activeProfile == "tenfoot"
      then "${pkgs.gamescope}/bin/gamescope -W 3840 -H 2160 -w 3840 -h 2160 -f -e -r 120 -- ${pkgs.steam}/bin/steam -tenfoot"
      else "${pkgs.steam}/bin/steam -silent -pipewire";
  };
}
