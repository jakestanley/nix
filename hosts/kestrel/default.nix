{ pkgs, ... }:

let
  publicKeys = (import ../../modules/nixos/identities.nix { }).publicKeys;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/base.nix
    ../../modules/nixos/ssh.nix
    ../../modules/nixos/home-manager.nix
    ./encryption.nix
    ./hibernate.nix
    ./desktop.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "max";
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "kestrel";

  home-manager.extraSpecialArgs = {
    hostname = "kestrel";
  };
  system.nixos.tags = [ "kestrel" ];

  users.users.jake = {
    home = "/home/work";
    openssh.authorizedKeys.keys = [
      publicKeys.turing
    ];
  };

  system.stateVersion = "26.05";
}
