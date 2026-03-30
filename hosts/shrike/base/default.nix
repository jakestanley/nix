{ pkgs, lib, activeProfile, ... }:

let
  publicKeys = (import ../../../modules/nixos/identities.nix {}).publicKeys;
in
{
  imports = [ ./greetd.nix ./plasma.nix ./docker.nix ];
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

  systemd.services.docker = {
    after = [ "mnt-data.mount" ];
    requires = [ "mnt-data.mount" ];
  };

  services.sleepOnLan.enable = true;
  services.sleepOnLan.openFirewall = true;

  services.sunshine = {
    enable = activeProfile == "desktop";
    package = lib.mkIf (activeProfile == "desktop") (pkgs.sunshine.override {
      cudaSupport = true;
    });
    autoStart = activeProfile == "desktop";
    capSysAdmin = activeProfile == "desktop";
    openFirewall = activeProfile == "desktop";
  };

}
