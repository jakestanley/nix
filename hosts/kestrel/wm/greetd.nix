{ pkgs, ... }:

let
  startPlasmaWayland = pkgs.writeShellScript "start-plasma-wayland" ''
    exec ${pkgs.kdePackages.plasma-workspace}/libexec/plasma-dbus-run-session-if-needed \
      ${pkgs.kdePackages.plasma-workspace}/bin/startplasma-wayland
  '';
in
{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd ${startPlasmaWayland}";
        user = "greeter";
      };
    };
  };

  # pam_fscrypt needs to lock key material in memory; raise the limit for greetd.
  systemd.services.greetd.serviceConfig.LimitMEMLOCK = "infinity";
}
