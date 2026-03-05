{ pkgs, ... }:

{
  services.sunshine = {
    enable = true;
    package = pkgs.sunshine.override {
      cudaSupport = true;
      autoAddDriverRunpath = true;
    };
    autoStart = true;
    capSysAdmin = false;
    openFirewall = true;
  };
}
