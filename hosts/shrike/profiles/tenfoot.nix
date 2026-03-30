{ pkgs, lib, activeProfile, ... }:

{
  environment.systemPackages = lib.optionals (activeProfile == "tenfoot") (with pkgs; [
    # tenfoot-specific packages
  ]);
}
