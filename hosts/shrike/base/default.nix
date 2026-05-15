{ inputs, pkgs, lib, ... }:

let
  publicKeys = (import ../../../modules/nixos/identities.nix {}).publicKeys;
in
{
  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
    ./docker.nix
    ./desktop.nix
    ./greetd.nix
    ./plasma.nix
    ../../../modules/nixos/nvidia.nix
    ./gaming.nix
    ./sleep-on-lan.nix
    ./reboot-to-windows.nix
  ];
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };
  boot.kernelPackages = pkgs.linuxPackages_latest;
  # Prevent shrike from resuming kestrel's hibernation image on shared hardware.
  boot.kernelParams = [ "noresume" ];

  networking.hostName = "shrike";
  system.nixos.tags = [ "shrike" ];

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
  ];

  systemd.services.docker = {
    after = [ "mnt-data.mount" ];
    requires = [ "mnt-data.mount" ];
  };

  services.sleepOnLan.enable = true;
  services.sleepOnLan.openFirewall = true;

}
