{ ... }:

let 
  publicKeys = (import ../../modules/nixos/identities.nix {}).publicKeys;
  lanInterface = "eno1";
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/base.nix
    ../../modules/nixos/home-manager.nix
    ../../modules/nixos/ssh.nix
    ./homelab
  ];
  _module.args.lanInterface = lanInterface;

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "max";
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # Hardware config mounts ZFS datasets (data/media, data/archive). Import the pool at boot.
  boot.supportedFilesystems = [ "zfs" ];

  networking.hostName = "adler";
  networking.hostId = "2a0f5297";

  virtualisation.docker.enable = false;

  users.users.jake.openssh.authorizedKeys.keys = [
    publicKeys.turing
    publicKeys.shrike
  ];

  home-manager.extraSpecialArgs = {
    hostname = "adler";
  };

  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  system.stateVersion = "26.05";
}
