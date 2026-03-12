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

    services.nginx.virtualHosts = lib.mapAttrs (name: cfg: {
        serverName = "${name}.stanley.arpa";
        forceSSL = true;
        sslCertificate = "/etc/homelab/certs/live/wildcard_stanley_arpa/fullchain.pem";
        sslCertificateKey = "/etc/homelab/certs/live/wildcard_stanley_arpa/privkey.pem";
        locations."/" = {
            proxyPass = "http://${cfg.upstream.host}:${toString cfg.upstream.port}";
            proxyWebsockets = true;
        };
        locations."= /healthz".return = "200";
        
    } // lib.optionalAttrs (name == "demucs") {
        extraConfig = ''
            client_max_body_size 256m;
            proxy_read_timeout 300s;
            proxy_send_timeout 300s;
            send_timeout 300s;
            '';
        }) registry.services;
}
