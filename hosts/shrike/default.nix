{ lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./base
    ./base/desktop.nix
    ./base/nvidia.nix
    ./base/gaming.nix
    ./base/sleep-on-lan.nix
    ./base/reboot-to-windows.nix
    ../../modules/nixos/docker.nix
    ../../modules/nixos/home-manager.nix
    ../../modules/nixos/ssh.nix
  ];

  specialisation.gaming.configuration = {
    virtualisation.docker.enable = lib.mkForce false;
    hardware.nvidia-container-toolkit.enable = lib.mkForce false;
  };

  system.stateVersion = "26.05";
}
