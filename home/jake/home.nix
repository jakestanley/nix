{ config, lib, pkgs, hostname ? null, ... }:

let
  hostModule = if hostname == null then null else ./hosts + "/${hostname}.nix";
in

{
  home.username = "jake";
  home.stateVersion = "26.05";
  home.file.".gitconfig".text = ''
    [include]
    	path = ${config.xdg.configHome}/git/config
  '';

  programs.home-manager.enable = true;

  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;
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

    git = {
      enable = true;
      settings = {
        user.name = "Jake Stanley";
        user.email = "mail@jakestanley.co.uk";

        core = {
          editor = "vim";
          whitespace = "trailing-space,space-before-tab,indent-with-non-tab";
          excludesfile = "~/.gitignore_global";
          autocrlf = "input";
        };

        push.default = "simple";
        init.defaultBranch = "main";

        alias = {
          ll = "!x() { git --no-pager log --pretty=tformat:\"%Cred%h %Cgreen%s %Cblue(%cn, %cr)\" --decorate -n$1;}; x";
          url = "remote get-url --push origin";

          co = "checkout";
          cb = "checkout -b";
          db = "branch -D";

          s = "status";

          eat = "stash --include-untracked";
          poop = "stash pop";

          pullr = "pull --rebase";
          amend = "commit --amend";
        };
      };
    };
  };

  imports =
    [
      ./platforms/linux.nix
      ./platforms/darwin.nix
    ]
    ++ lib.optional (hostname != null && builtins.pathExists hostModule) hostModule;
}
