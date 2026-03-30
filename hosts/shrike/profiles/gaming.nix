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
in
{
  imports = [ ../base/plasma.nix ];

  services.desktopManager.plasma6.enable = true;

  virtualisation.docker.enable = lib.mkForce false;
  hardware.nvidia-container-toolkit.enable = lib.mkForce false;

  systemd.user.services.steam-autostart = {
    description = "Start Steam when the graphical session starts";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig.ExecStart = "${pkgs.steam}/bin/steam -silent";
  };
}
