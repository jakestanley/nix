{ pkgs, ... }:

{
  services.desktopManager.plasma6.enable = true;
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
