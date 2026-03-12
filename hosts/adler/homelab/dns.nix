{ lib, registry, ... }:



#   shed:
#     hostname: shed.stanley.arpa
#     ip: 10.92.8.30

#   shrike:
#     hostname: shrike.stanley.arpa
#     ip: 10.92.8.4

{   
    # Nix way is to let Nix handle the config, so unlike on Ubuntu we won't have many files
    networking.firewall.allowedTCPPorts = [ 53 ];
    networking.firewall.allowedUDPPorts = [ 53 ];
    services.dnsmasq = {
        enable = true;
        settings = {
            # hosts:
            #   adler:
            #     hostname: adler.stanley.arpa
            #     ip: 10.92.8.6
            host-record = lib.mapAttrsToList
            (name: host: "${name}.stanley.arpa,${host.ip}")
            registry.hosts;
        };
    };

    # raw example (no functions)
    # services.dnsmasq = {
    #   enable = true;
    #   settings = {
    #     host-record = [
    #       "adler.stanley.arpa,10.66.6.6"
    #       "shrike.stanley.arpa,10.66.6.7"
    #     ];
    #   };
    # };
}
