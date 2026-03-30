{ pkgs, lib, activeProfile, ... }:

{
  services.sunshine = {
    enable = activeProfile == "desktop";
    package = lib.mkIf (activeProfile == "desktop") (pkgs.sunshine.override {
      cudaSupport = true;
    });
    autoStart = activeProfile == "desktop";
    capSysAdmin = activeProfile == "desktop";
    openFirewall = activeProfile == "desktop";
  };
}
