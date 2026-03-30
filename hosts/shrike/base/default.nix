{ pkgs, lib, activeProfile, ... }:

let
  publicKeys = (import ../../../modules/nixos/identities.nix {}).publicKeys;
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
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "max";
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "shrike";

  users.users.jake.openssh.authorizedKeys.keys = [
    publicKeys.turing
    publicKeys.adler
  ];

  home-manager.extraSpecialArgs = {
    hostname = "shrike";
  };

  systemd.services.wake-on-lan-enp4s0 = {
    description = "Enable wake-on-LAN on enp4s0";
    after = [ "NetworkManager.service" ];
    wants = [ "NetworkManager.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.ethtool}/bin/ethtool -s enp4s0 wol g";
    };
  };

  security.pki.certificateFiles = [ ../../../ca.crt ];

  environment.systemPackages = [
    pkgs.vscode
    pkgs.gparted
    pkgs.duf
  ];

  virtualisation.docker.enable = true;
  hardware.nvidia-container-toolkit.enable = true;

  systemd.services.docker = {
    after = [ "mnt-data.mount" ];
    requires = [ "mnt-data.mount" ];
  };

  services.sleepOnLan.enable = true;
  services.sleepOnLan.openFirewall = true;

  services.displayManager.sddm.enable = lib.mkForce false;
  services.greetd = {
    enable = true;
    settings = {
      initial_session = greetdSession;
      default_session = greetdSession;
    };
  };
}
