{ pkgs, ... }:

{
  systemd.user.services.steam-autostart = {
    description = "Start Steam when the graphical session starts";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig.ExecStart = "${pkgs.steam}/bin/steam -silent";
  };
}
