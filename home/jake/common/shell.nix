{ ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    initContent = ''
      bindkey '^R' history-incremental-search-backward
      bindkey -M emacs '^R' history-incremental-search-backward
      bindkey -M viins '^R' history-incremental-search-backward
    '';
    oh-my-zsh = {
      enable = false;
    };
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
}
