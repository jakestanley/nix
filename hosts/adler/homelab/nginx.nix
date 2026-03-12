{ lib, registry, ... }:

let
  commonProxyConfig = ''
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  '';
in

{
    services.nginx.enable = true;

#   rtx:
#     dns: rtx.stanley.arpa
#     proxy_host: adler
#     upstream:
#       host: shrike
#       port: 20031
#       scheme: http

    services.nginx.virtualHosts = lib.mapAttrs (name: cfg:
        lib.recursiveUpdate {
            serverName = "${name}.stanley.arpa";
            forceSSL = true;
            sslCertificate = "/etc/homelab/certs/live/wildcard_stanley_arpa/fullchain.pem";
            sslCertificateKey = "/etc/homelab/certs/live/wildcard_stanley_arpa/privkey.pem";
            
            locations."/" = {
                proxyPass = "http://${registry.hosts.${cfg.upstream.host}.ip}:${toString cfg.upstream.port}";
                proxyWebsockets = true;
                extraConfig = commonProxyConfig;
            };

            locations."= /healthz".return = "200";
        } (lib.optionalAttrs (name == "demucs") {
            locations."/".extraConfig = commonProxyConfig + ''
                    client_max_body_size 256m;
                    proxy_read_timeout 300s;
                    proxy_send_timeout 300s;
                    send_timeout 300s;
                '';
            })
        ) registry.services;
    }
