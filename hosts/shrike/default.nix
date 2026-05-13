{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./base
    ../../modules/nixos/home-manager.nix
    ../../modules/nixos/ssh.nix
  ];

  system.stateVersion = "26.05";
}
