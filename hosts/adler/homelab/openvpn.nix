{ ... }:

let
  ovpnDir = "/etc/openvpn";
  serverCert = "server_YeWnWJLw5SiBcE91";
in

{

    # VPN masquerade rule
    networking.nat = {
        enable = true;
        internalInterfaces = [ "tun0" ];
        externalInterface = "eno1";
    };

  services.openvpn.servers.stanley = {
    config = ''
      port 1194
      proto udp
      dev tun
      user nobody
      group nogroup
      persist-key
      persist-tun
      keepalive 10 120
      topology subnet
      server 10.8.0.0 255.255.255.0
      ifconfig-pool-persist ${ovpnDir}/ipp.txt
      push "dhcp-option DNS 10.92.8.6"
      push "dhcp-option DOMAIN stanley.arpa"
      push "dhcp-option DOMAIN-SEARCH stanley.arpa"
      push "redirect-gateway def1 bypass-dhcp"
      dh none
      ecdh-curve prime256v1
      tls-crypt ${ovpnDir}/tls-crypt.key
      crl-verify ${ovpnDir}/crl.pem
      ca ${ovpnDir}/ca.crt
      cert ${ovpnDir}/${serverCert}.crt
      key ${ovpnDir}/${serverCert}.key
      auth SHA256
      cipher AES-128-GCM
      ncp-ciphers AES-128-GCM
      tls-server
      tls-version-min 1.2
      tls-cipher TLS-ECDHE-ECDSA-WITH-AES-128-GCM-SHA256
      client-config-dir ${ovpnDir}/ccd
      status /var/log/openvpn/status.log
      verb 3
    '';
  };

  networking.firewall.allowedUDPPorts = [ 1194 ];

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  systemd.tmpfiles.rules = [
    "d ${ovpnDir} 0755 root root -"
    "d ${ovpnDir}/ccd 0755 root root -"
    "d /var/log/openvpn 0755 root root -"
    "z ${ovpnDir}/ca.crt 0644 root root -"
    "z ${ovpnDir}/ca.key 0600 root root -"
    "z ${ovpnDir}/${serverCert}.crt 0644 root root -"
    "z ${ovpnDir}/${serverCert}.key 0600 root root -"
    "z ${ovpnDir}/tls-crypt.key 0600 root root -"
    "z ${ovpnDir}/crl.pem 0644 root root -"
    "z ${ovpnDir}/ipp.txt 0644 root root -"
  ];
}
