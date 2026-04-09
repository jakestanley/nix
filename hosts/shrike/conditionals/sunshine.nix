{ pkgs, lib, activeProfile, ... }:

let
  sunshineEnabled = activeProfile == "desktop" || activeProfile == "tenfoot";
in
{
  services.sunshine = {
    enable = sunshineEnabled;
    package = lib.mkIf sunshineEnabled (pkgs.sunshine.override {
      cudaSupport = true;
    });
    autoStart = activeProfile == "desktop";
    capSysAdmin = sunshineEnabled;
    openFirewall = sunshineEnabled;
  };
}
