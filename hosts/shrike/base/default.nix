{ pkgs, lib, activeProfile, ... }:

let
  publicKeys = (import ../../../modules/nixos/identities.nix {}).publicKeys;
in
{
  imports = [ ./docker.nix ];
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
    pkgs.duf
  ] ++ pkgs.lib.optionals (activeProfile != "tenfoot") [
    pkgs.vscode
    pkgs.gparted
  ];

  systemd.services.docker = {
    after = [ "mnt-data.mount" ];
    requires = [ "mnt-data.mount" ];
  };

  services.sleepOnLan.enable = true;
  services.sleepOnLan.openFirewall = true;

}
