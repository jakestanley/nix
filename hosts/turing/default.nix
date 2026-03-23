{ pkgs, inputs, ... }:

{
  imports = [
    ./dock.nix
    ./brew.nix
    ./defaults.nix
  ];

  networking.hostName = "turing";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.jake = {
    home = "/Users/jake";
    shell = pkgs.zsh;
  };
  system.primaryUser = "jake";

  programs.zsh.enable = true;

  environment.systemPackages = [
    pkgs.vim
    inputs.cherri.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  security.sudo.extraConfig = ''
    Cmnd_Alias TUNING_DOCK_SWITCH = \
      /Users/jake/git/github.com/jakestanley/nixos-shrike/scripts/switch-turing-dock.sh work, \
      /Users/jake/git/github.com/jakestanley/nixos-shrike/scripts/switch-turing-dock.sh personal
    jake ALL=(root) NOPASSWD: TUNING_DOCK_SWITCH
  '';

  system.stateVersion = 6;
}
