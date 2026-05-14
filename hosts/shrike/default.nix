{ inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./base
    ../../modules/nixos/home-manager.nix
    ../../modules/nixos/ssh.nix
  ];

  home-manager.sharedModules = [
    inputs.plasma-manager.homeModules.plasma-manager
  ];

  system.stateVersion = "26.05";
}
