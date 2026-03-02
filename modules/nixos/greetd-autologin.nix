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
  services.displayManager.sddm.enable = lib.mkForce false;

  services.greetd = {
    enable = true;
    settings = {
      initial_session = plasmaSession;
      default_session = plasmaSession;
    };
  };
}
