{ ... }:

let 
  publicKeys = (import ../../modules/nixos/public-keys.nix {}).publicKeys;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/base.nix
    ../../modules/nixos/docker.nix
    ../../modules/nixos/home-manager.nix
    ../../modules/nixos/ssh.nix
    ./homelab
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "max";
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # Hardware config mounts ZFS datasets (data/media, data/archive). Import the pool at boot.
  boot.supportedFilesystems = [ "zfs" ];

  networking.hostName = "adler";
  networking.hostId = "2a0f5297";

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
