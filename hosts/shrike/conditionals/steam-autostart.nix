{ pkgs, activeProfile, ... }:

{
  systemd.user.services.steam-autostart = {
    enable = true;
    description = "Start Steam when the graphical session starts";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig.ExecStart = if activeProfile == "tenfoot"
      then "${pkgs.steam}/bin/steam -tenfoot"
      else "${pkgs.steam}/bin/steam -silent";
  };
}
