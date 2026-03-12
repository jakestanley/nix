{ ... }:

{
  services.plex = {
    enable = true;
    dataDir = "/var/lib/plexmediaserver";
    openFirewall = true;
  };
}