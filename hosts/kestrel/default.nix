{ pkgs, ... }:

let
  publicKeys = (import ../../modules/nixos/identities.nix { }).publicKeys;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/base.nix
    ../../modules/nixos/ssh.nix
    ./encryption.nix
    ./hibernate.nix
    ./desktop.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "max";
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "kestrel";
  system.nixos.tags = [ "kestrel" ];

  users.users.jake = {
    home = "/home/work";
    openssh.authorizedKeys.keys = [
      publicKeys.turing
    ];
  };

  system.stateVersion = "26.05";
}
