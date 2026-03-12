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

    _module.args.registry = {
      hosts = {
        adler = { ip = "10.66.6.6"; };
        shrike = { ip = "10.66.6.7"; };
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