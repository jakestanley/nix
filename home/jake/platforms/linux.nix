{ lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
  home.homeDirectory = "/home/jake";

  programs.git.settings = {
    diff.tool = "meld";
    difftool.prompt = false;
    difftool.meld.cmd = "meld \"$LOCAL\" \"$REMOTE\"";
    difftool.meld.trustExitCode = true;
  };
}
