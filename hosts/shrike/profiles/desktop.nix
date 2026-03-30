{ pkgs, lib, activeProfile, ... }:

{
  environment.systemPackages = lib.optionals (activeProfile == "desktop") (with pkgs; [
    # desktop-specific packages
  ]);
}
