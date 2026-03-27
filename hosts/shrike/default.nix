{ lib, pkgs, ... }:

let
  publicKeys = (import ../../modules/nixos/identities.nix {}).publicKeys;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/docker.nix
    ../../modules/nixos/home-manager.nix
    ../../modules/nixos/ssh.nix
    ../../modules/nixos/plasma.nix
    ../../modules/nixos/greetd-autologin.nix
    ../../modules/nixos/nvidia.nix
    ../../modules/nixos/sunshine.nix
    ../../modules/nixos/gaming.nix
    ../../modules/nixos/sleep-on-lan.nix
    ../../modules/nixos/reboot-to-windows.nix
  ];

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

  # homelab self signed cert
  security.pki.certificateFiles = [ ../../ca.crt ];

  environment.systemPackages = [
    pkgs.vscode
    pkgs.gparted
    # TODO make this a common package
    pkgs.duf
  ];

  virtualisation.docker.enable = true;
  hardware.nvidia-container-toolkit.enable = true;

  services.sleepOnLan.enable = true;
  services.sleepOnLan.openFirewall = true;

  specialisation.gaming.configuration = {
    # Long-lived systemd units stay enabled in the default system and are
    # explicitly forced off here when the gaming boot entry must not run them.
    services.sunshine.enable = lib.mkForce false;
    virtualisation.docker.enable = lib.mkForce false;
    hardware.nvidia-container-toolkit.enable = lib.mkForce false;
  };

  system.stateVersion = "26.05";
}
