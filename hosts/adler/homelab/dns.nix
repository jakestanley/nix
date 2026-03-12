{ lib, registry, ... }:

# hosts:
#   adler:
#     hostname: adler.stanley.arpa
#     ip: 10.92.8.6

#   shed:
#     hostname: shed.stanley.arpa
#     ip: 10.92.8.30

#   shrike:
#     hostname: shrike.stanley.arpa
#     ip: 10.92.8.4

{
    services.dnsmasq = {
        enable = true;
        settings = {
            host-record = lib.mapAttrsToList
            (name: cfg: "${name}.stanley.arpa,${cfg.ip}")
            registry.hosts;
        };
    };
}
