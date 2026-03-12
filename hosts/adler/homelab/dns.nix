{ lib, registry, ... }:

{
    services.dnsmasq = {
        enable = true;
        # settings = {
        #     host-record = lib.mapAttrsToList
        #     (name: cfg: "${name}.stanley.arpa,${cfg.ip}")
        #     config.homelab.hosts;
        # };
    };
}
