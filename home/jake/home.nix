{ lib, hostname ? null, ... }:

let
  hostModule = if hostname == null then null else ./hosts + "/${hostname}.nix";
in

{
  home.username = "jake";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  imports =
    [
      ./common/git.nix
      ./common/shell.nix
      ./common/ssh.nix
      ./common/cli.nix
      ./common/editor.nix
      ./platforms/linux.nix
      ./platforms/darwin.nix
    ]
    ++ lib.optional (hostname != null && builtins.pathExists hostModule) hostModule;
}
