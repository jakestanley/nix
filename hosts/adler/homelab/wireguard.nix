{ pkgs, lib, lanInterface, ... }:

let
  wireguardPeers = (import ../../../modules/nixos/identities.nix {}).wireguardPeers;
in

{
  networking.wg-quick.interfaces.wg0 = {
    address = [ "10.9.0.1/24" ];
    listenPort = 51820;
    privateKeyFile = "/etc/wireguard/private.key";

    peers = lib.mapAttrsToList (name: cfg: {
      publicKey = cfg.publicKey;
      allowedIPs = [ "${cfg.ip}/32" ];
    }) wireguardPeers;

    postUp = ''
      ${pkgs.iptables}/bin/iptables -A FORWARD -i wg0 -j ACCEPT
      ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -o ${lanInterface} -j MASQUERADE
    '';

    preDown = ''
      ${pkgs.iptables}/bin/iptables -D FORWARD -i wg0 -j ACCEPT
      ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -o ${lanInterface} -j MASQUERADE
    '';
  };

  networking.firewall.allowedUDPPorts = [ 51820 ];

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
}