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
  nixpkgs.config.allowUnfree = true;

  users.users.jake = {
    home = "/Users/jake";
    shell = pkgs.zsh;
  };
  system.primaryUser = "jake";

  programs.zsh.enable = true;

  environment.systemPackages = [
    pkgs.vim
    pkgs.duf
    pkgs.tree
    pkgs.docker
    pkgs.ncdu
    pkgs.wireguard-tools
    pkgs.bash
    pkgs.readline
    pkgs.awscli
    pkgs.pipx
    pkgs.ffmpeg
    pkgs.id3v2
    pkgs.python312
    pkgs.htop
    pkgs.ollama
    pkgs.keyfinder-cli
    # non-graphical, work only
    pkgs.redis
    # graphical. expand "platforms" when searching here: https://search.nixos.org/packages?channel=25.11
    pkgs.firefox
    pkgs.zed-editor
    # pkgs.prismlauncher (broken on mac)
    pkgs.telegram-desktop
    # pkgs.spotify (broken on mac?)
    pkgs.vscode
    pkgs.discord
    # mac only (in case i merge later)
    pkgs.zoom-us
    # pkgs.blender (currently broken)
    pkgs.cyberduck
    pkgs.claude-code
    pkgs.chatgpt
    pkgs.postman
    # pkgs.teams (login problems)
    pkgs.google-chrome
    pkgs.upscayl
    # non-graphical, mac only
    pkgs.openconnect
    inputs.cherri.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  security.sudo.extraConfig = ''
    Cmnd_Alias TUNING_DOCK_SWITCH = \
      /Users/jake/git/github.com/jakestanley/nix/scripts/switch-turing-dock.sh work, \
      /Users/jake/git/github.com/jakestanley/nix/scripts/switch-turing-dock.sh personal
    jake ALL=(root) NOPASSWD: TUNING_DOCK_SWITCH
  '';

  system.stateVersion = 6;
}
