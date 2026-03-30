{ lib, profile, ... }:

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
    (./profiles + "/${profile}.nix")
  ];

  specialisation.tenfoot.configuration.imports  = [ ./profiles/tenfoot.nix ];
  specialisation.desktop.configuration.imports  = [ ./profiles/desktop.nix ];
  specialisation.gaming.configuration.imports   = [ ./profiles/gaming.nix ];

  system.stateVersion = "26.05";
}
