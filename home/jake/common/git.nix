{ config, lib, ... }:

{
  home.file.".gitconfig".text = ''
    [include]
      path = ${config.xdg.configHome}/git/config
  '';

  home.activation.ensureGitignoreGlobal = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    target="${config.home.homeDirectory}/.gitignore_global"
    if [ ! -e "$target" ]; then
      $DRY_RUN_CMD cp ${./config/gitignore_global.default} "$target"
      $DRY_RUN_CMD chmod 0644 "$target"
    fi
  '';

  programs.git = {
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
}
