# tests/dns.nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.testers.runNixOSTest {
  name = "dnsmasq-records";

  nodes.machine = { ... }: {
    services.dnsmasq = {
      enable = true;
      settings = {
        host-record = [
          "adler.stanley.arpa,10.92.8.6"
          "shrike.stanley.arpa,10.92.8.4"
        ];
      };
    };
  };

  testScript = ''
    machine.wait_for_unit("dnsmasq.service")

    print(machine.succeed("find /etc/dnsmasq.d/ -type f -exec cat {} +"))
    print(machine.succeed("cat /etc/dnsmasq.conf"))

    machine.succeed("cat /etc/dnsmasq.conf")
    machine.succeed("dig @127.0.0.1 adler.stanley.arpa | grep 10.92.8.6")
  '';
}