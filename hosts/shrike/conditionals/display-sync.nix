{ pkgs, activeProfile, ... }:

let
  displaySync = pkgs.writers.writePython3Bin "display-sync" { } (
    builtins.readFile ../scripts/display-sync.py
  );
in
{
  systemd.user.services.display-sync = {
    enable = activeProfile == "desktop";
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

  environment.systemPackages = pkgs.lib.optionals (activeProfile == "desktop") [
    displaySync
    pkgs.kdePackages.libkscreen
  ];
}
