{ pkgs, lib, activeProfile, ... }:

{
  environment.systemPackages = lib.optionals (activeProfile == "gaming") (with pkgs; [
    # gaming-specific packages
  ]);
}
