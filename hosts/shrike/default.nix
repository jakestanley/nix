{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./base
    ./base/desktop.nix
    ./base/greetd.nix
    ./base/plasma.nix
    ./base/nvidia.nix
    ./base/gaming.nix
    ./base/sleep-on-lan.nix
    ./base/reboot-to-windows.nix
    ../../modules/nixos/docker.nix
    ../../modules/nixos/home-manager.nix
    ../../modules/nixos/ssh.nix
  ];

  system.stateVersion = "26.05";
}
