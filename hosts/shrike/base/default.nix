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

  environment.etc."NetworkManager/system-connections/br0.nmconnection" = {
    mode = "0600";
    text = ''
      [connection]
      id=br0
      type=bridge
      interface-name=br0

      [bridge]
      stp=false

      [ipv4]
      method=auto

      [ipv6]
      method=ignore
    '';
  };

  environment.etc."NetworkManager/system-connections/enp4s0-bridge-slave.nmconnection" = {
    mode = "0600";
    text = ''
      [connection]
      id=enp4s0-bridge-slave
      type=ethernet
      interface-name=enp4s0
      master=br0
      slave-type=bridge
    '';
  };

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
