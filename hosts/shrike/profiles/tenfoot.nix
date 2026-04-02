{ pkgs, lib, activeProfile, ... }:

{
  hardware.uinput.enable = true;
  users.users.jake.extraGroups = [ "input" ];

  environment.systemPackages = lib.optionals (activeProfile == "tenfoot") (with pkgs; [
    # tenfoot-specific packages
  ]);
}
