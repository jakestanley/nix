{ inputs, pkgs, lib, ... }:

let
  publicKeys = (import ../../modules/nixos/identities.nix { }).publicKeys;
in
{
  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
    ./hardware-configuration.nix
    ../../modules/nixos/base.nix
    ../../modules/nixos/ssh.nix
    ../../modules/nixos/home-manager.nix
    ./encryption.nix
    ./hibernate.nix
    ./wm/plasma.nix
    ./wm/greetd.nix
    ./hardening.nix
  ];

  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.systemd-boot.consoleMode = "max";
  boot.loader.efi.canTouchEfiVariables = true;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "kestrel";

  home-manager.sharedModules = [
    inputs.plasma-manager.homeModules.plasma-manager
  ];

  home-manager.extraSpecialArgs = {
    hostname = "kestrel";
  };
  system.nixos.tags = [ "kestrel" ];

  users.users.jake = {
    home = "/home/work";
    openssh.authorizedKeys.keys = [
      publicKeys.turing
    ];
    packages = with pkgs; [ awscli2 ];
  };

  system.stateVersion = "26.05";
}
