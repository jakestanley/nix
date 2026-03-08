{ ... }:

{
  home.file.".vimrc".source = ./config/vimrc;

  programs.vim = {
    defaultEditor = true;
    enable = true;

    extraConfig = builtins.readFile ./config/vimrc;
  };
}
