{ pkgs, ... }:

{
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
  ];

  # Adopt Homebrew declaratively without removing unmanaged packages yet.
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = false;
      cleanup = "none";
    };

    # Starter set for desktop app management; expand incrementally.
    casks = [
      "diffmerge"
      "jetbrains-toolbox"
      "lm-studio"
      "visual-studio-code"
      "ableton-live-standard@11"
    ];
  };

  system.stateVersion = 6;
}
