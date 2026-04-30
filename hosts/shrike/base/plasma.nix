{ pkgs, ... }:

{
  services.desktopManager.plasma6.enable = true;

  xdg.portal = {
    extraPortals = [ pkgs.xdg-desktop-portal-wlr ];
    config.common = {
      "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
    };
  };

  environment.etc."xdg/xdg-desktop-portal-wlr/config".text = ''
    [screencast]
    chooser_type=none
  '';
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
