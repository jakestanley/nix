{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/base.nix
    ../../modules/nixos/home-manager.nix
    ../../modules/nixos/ssh.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "max";
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "adler";

  users.users.jake.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL0q1CwSf4NG0jPtBtWabETld24LR2QsIB4XQLpukXSK jake@Jacobs-MacBook-Pro.local"
  ];

  home-manager.extraSpecialArgs = {
    hostname = "adler";
  };

  system.stateVersion = "26.05";
}
