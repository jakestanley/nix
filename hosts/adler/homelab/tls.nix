{ registry, ... }:

{
  systemd.tmpfiles.rules = [
    "d /etc/homelab/certs 0755 root root -"
    "d /etc/homelab/certs/live/wildcard_stanley_arpa 0755 root root -"
    "z /etc/homelab/certs/live/wildcard_stanley_arpa/fullchain.pem 0644 root root -"
    "z /etc/homelab/certs/live/wildcard_stanley_arpa/privkey.pem 0600 root root -"
  ];
}
