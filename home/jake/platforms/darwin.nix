{ lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  home.homeDirectory = "/Users/jake";

  # vim-full defaults to a GTK2 GUI on Darwin, which fails to compile (image.c: no member 'scale'
  # in 'struct Gui'). Terminal vim is all that's used here, so build it without the GUI.
  programs.vim.packageConfigurable = pkgs.vim-full.override { guiSupport = "none"; };

  programs.git.settings = {
    diff.tool = "diffmerge";
    difftool.prompt = false;
    difftool.diffmerge.cmd = "diffmerge \"$LOCAL\" \"$REMOTE\"";
    difftool.diffmerge.trustExitCode = true;
  };
}
