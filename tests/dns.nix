# tests/dns.nix
# you'll need kvm access
# - `sudo usermod -aG kvm $USER`
# - log out, then back in and check `groups`
# - `nix --extra-experimental-features "nix-command" build --file tests/dns.nix -L` (-L flag prevents logs being truncated)
# - nix caches inputs by hash, so if nothing changed and the test passed then it won't run and just return the last exit code. Add --rebuild
{ pkgs ? import <nixpkgs> {} }:

pkgs.testers.runNixOSTest {
  name = "dnsmasq-records";

  nodes.machine = { ... }: {

    _module.args.registry = {
      hosts = {
        adler = { ip = "10.66.6.6"; };
        shrike = { ip = "10.66.6.7"; };
      };
    };

    environment.systemPackages = [ pkgs.dig ];

    imports = [ ../hosts/adler/homelab/dns.nix ];
  };

  testScript = { nodes, ... }: ''
    dnsmasq_conf = "${nodes.machine.services.dnsmasq.configFile}"
  '' + builtins.readFile ./dns.py;
}