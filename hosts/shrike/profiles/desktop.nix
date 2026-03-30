{ pkgs, ... }:

let
  displaySync = pkgs.writers.writePython3Bin "display-sync" { } (builtins.readFile ../scripts/display-sync.py);
in
{

  systemd.user.services.steam-autostart = {
    description = "Start Steam when the graphical session starts";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig.ExecStart = "${pkgs.steam}/bin/steam -silent";
  };

  systemd.user.services.display-sync = {
    description = "Auto toggle HDMI outputs based on DisplayPort state";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${displaySync}/bin/display-sync";
      Restart = "always";
      RestartSec = 3;
    };
  };

  environment.systemPackages = [
    displaySync
    pkgs.kdePackages.libkscreen
  ];
}
