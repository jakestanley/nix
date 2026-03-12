{ lib, registry, ... }:

{
    services.nginx.enable = true;
    
#   rtx:
#     dns: rtx.stanley.arpa
#     proxy_host: adler
#     upstream:
#       host: shrike
#       port: 20031
#       scheme: http

    services.nginx.virtualHosts = lib.mapAttrs (name: service: {
        # name is rtx
        # cfg is proxy_host
        serverName = "${name}.stanley.arpa";
        # forceSSL = true;
        # # # sslCertificate = "" # TODO
        # # locations."/" = {
        # #     proxyPass = "http://${cfg.host}:${toString cfg.port}";
        # #     proxyWebsockets = true;
        # # };
        # # locations."= /healthz".return = "200";
    }) registry.services;
}

# {
#     services.nginx = {
#         enable = true;
#     };
#     services.nginx.virtualHosts = lib.mapAttrs (name: cfg: {
#         serverName = "${name}.stanley.arpa";
#         forceSSL = true;
#         # sslCertificate = "" # TODO
#         locations."/" = {
#             proxyPass = "http://${cfg.host}:${toString cfg.port}";
#             proxyWebsockets = true;
#         };
#         locations."= /healthz".return = "200";
#     }) config.homelab.services;
# }