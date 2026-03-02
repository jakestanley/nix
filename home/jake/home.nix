{ hostname, ... }:

{
  imports = [
    (./hosts + "/${hostname}.nix")
  ];

  home.username = "jake";
  home.homeDirectory = "/home/jake";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;
      oh-my-zsh = {
        enable = false;
      shellAliases = {
        rm = "rm -I";
        hmtest = "echo HOME_MANAGER_IS_WORKING";
      };
      setOptions = [
        "HIST_FIND_NO_DUPS"
      ];
      sessionVariables = {
        EDITOR = "vim";
      };
    };
  };
}
