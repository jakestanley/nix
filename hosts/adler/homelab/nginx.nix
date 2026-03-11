{ ... }:

{
    services.nginx.virtualHosts = lib.mapAttrs (name: cfg: {
        serverName = "${name}.stanley.arpa";
        forceSSL = true;
        # sslCertificate = "" # TODO
        locations."/" = {
            proxyPass = "http://${cfg.host}:${toString cfg.port}";
            proxyWebsockets = true;
        };
        locations."= /healthz".return = "200";
    }) config.homelab.services;
}

