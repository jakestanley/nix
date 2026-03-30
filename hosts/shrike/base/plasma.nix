{ pkgs, ... }:

{
  services.xserver.enable = false;
  services.desktopManager.plasma6.enable = true;

  services.xserver.excludePackages = with pkgs; [
    xterm
  ];

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
