{ lib, pkgs, ... }:

let
  startPlasmaWayland = pkgs.writeShellScriptBin "startplasma-wayland-autologin" ''
    exec ${pkgs.kdePackages.plasma-workspace}/libexec/plasma-dbus-run-session-if-needed \
      ${pkgs.kdePackages.plasma-workspace}/bin/startplasma-wayland
  '';
  plasmaSession = {
    user = "jake";
    command = "${startPlasmaWayland}/bin/startplasma-wayland-autologin";
  };
  displaySync = pkgs.writers.writePython3Bin "display-sync" { } (builtins.readFile ../scripts/display-sync.py);
in
{
  imports = [ ../base/plasma.nix ../base/sunshine.nix ];

  services.displayManager.sddm.enable = lib.mkForce false;
  services.desktopManager.plasma6.enable = lib.mkForce true;

  services.greetd = {
    enable = lib.mkForce true;
    settings = lib.mkForce {
      initial_session = plasmaSession;
      default_session = plasmaSession;
    };
  };

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
