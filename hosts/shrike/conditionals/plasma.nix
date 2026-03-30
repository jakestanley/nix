{ pkgs, activeProfile, ... }:

{
  services.desktopManager.plasma6.enable =
    activeProfile == "desktop" || activeProfile == "gaming";
  services.xserver.xkb = {
    layout = "gb";
    variant = "";
  };

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa
    spectacle
    gwenview
    okular
    discover
    ark
    khelpcenter
    krdp
  ];
}
