{ pkgs, lib, activeProfile, ... }:

let
  startPlasmaWayland = pkgs.writeShellScriptBin "startplasma-wayland-autologin" ''
    exec ${pkgs.kdePackages.plasma-workspace}/libexec/plasma-dbus-run-session-if-needed \
      ${pkgs.kdePackages.plasma-workspace}/bin/startplasma-wayland
  '';
  plasmaSession = {
    user = "jake";
    command = "${startPlasmaWayland}/bin/startplasma-wayland-autologin";
  };
  gamescopeSession = {
    user = "jake";
    command = "steam-gamescope";
  };
  greetdSession = if activeProfile == "tenfoot" then gamescopeSession else plasmaSession;
in
{
  services.displayManager.sddm.enable = lib.mkForce false;
  services.greetd = {
    enable = true;
    settings = {
      initial_session = greetdSession;
      default_session = greetdSession;
    };
  };
}
