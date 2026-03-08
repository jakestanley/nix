{ pkgs, ... }:

{
  networking.hostName = "turing";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.jake = {
    home = "/Users/jake";
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  environment.systemPackages = [
    pkgs.vim
  ];

  system.stateVersion = 6;
}
