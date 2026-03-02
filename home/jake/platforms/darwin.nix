{ lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  home.homeDirectory = "/Users/jake";

  programs.git.settings = {
    diff.tool = "diffmerge";
    difftool.prompt = false;
    difftool.diffmerge.cmd = "diffmerge \"$LOCAL\" \"$REMOTE\"";
    difftool.diffmerge.trustExitCode = true;
  };
}
