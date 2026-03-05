{ ... }:

{
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = false;
    openFirewall = true;
  };
}
