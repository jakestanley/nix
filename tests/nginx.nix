{ pkgs ? import <nixpkgs> {} }:

# error: some outputs of '/nix/store/...drv' are not valid, so checking is not possible
# run a flake check:
# ``
pkgs.testers.runNixOSTest {
  name = "nginx-records";
  skipTypeCheck = true;

  # these packages will be available to the test script
  extraPythonPackages = p: [ p.crossplane ];

  nodes.machine = { ... }: {

#   rtx:
#     dns: rtx.stanley.arpa
#     proxy_host: adler
#     upstream:
#       host: shrike
#       port: 20031
#       scheme: http

# dummy certificate files
  systemd.tmpfiles.rules = [
    "d /etc/homelab/certs/live/wildcard_stanley_arpa 0755 root root -"
    "f /etc/homelab/certs/live/wildcard_stanley_arpa/fullchain.pem 0644 root root -"
    "f /etc/homelab/certs/live/wildcard_stanley_arpa/privkey.pem 0644 root root -"
  ];

    _module.args.registry = {
      hosts = {
        adler = { ip = "10.92.8.6"; };
        # real shrike for the curl test
        shrike = { ip = "10.92.8.4"; };
      };
      services = {
        rtx = {
          dns = "rtx.stanley.arpa";
          proxy_host = "adler";
          upstream = {
            host = "shrike";
            port = "20031";
            scheme = "http";
          };
        };
        demucs = {
          dns = "demucs.stanley.arpa";
          proxy_host = "adler";
          upstream = {
            host = "adler";
            port = "20032";
            scheme = "http";
          };
        };
      };
    };

    # These packages will be available to the VM, not the test host
    # environment.systemPackages = [ 
    #   (pkgs.python3.withPackages (ps: [ ps.crossplane ]))
    # ];

    imports = [ ../hosts/adler/homelab/nginx.nix ];
  };

  testScript = { nodes, ... }: builtins.readFile ./nginx.py;
}