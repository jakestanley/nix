{ pkgs, lib, activeProfile, ... }:

{
  hardware.uinput.enable = activeProfile == "tenfoot";
  users.users.jake.extraGroups = lib.optionals (activeProfile == "tenfoot") [ "input" ];

  environment.systemPackages = with pkgs; [
    # tenfoot-specific packages
  ];
}
