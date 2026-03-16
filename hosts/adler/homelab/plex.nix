{ ... }:

{
  services.plex = {
    enable = false;
    dataDir = "/var/lib/plexmediaserver";
    openFirewall = true;
  };
}