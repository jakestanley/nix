{ pkgs, ... }:

let
  publicKeys = (import ../../modules/nixos/identities.nix { }).publicKeys;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/base.nix
    ../../modules/nixos/ssh.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "max";
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "kestrel";

  users.users.jake.openssh.authorizedKeys.keys = [
    publicKeys.turing
  ];

  # TODO: import work profile once defined, e.g.:
  # imports = [ ./work.nix ];

  system.stateVersion = "26.05";
}
