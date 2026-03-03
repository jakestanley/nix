{ config, lib, pkgs, ... }:

let
  servicePort = import ../../sources/service-ports/ollama.nix;
  cfg = config.services.homelabOllama;
in
{
  options.services.homelabOllama = {
    enable = lib.mkEnableOption "homelab-ollama service wrapper";

    package = lib.mkPackageOption pkgs "homelab-ollama" { };

    ollamaPackage = lib.mkPackageOption pkgs "ollama" { };

    bindHost = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      example = "127.0.0.1";
      description = "Bind host passed to homelab-ollama via SERVICE_HOST.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = servicePort.port;
      description = "TCP port exposed by homelab-ollama via SERVICE_PORT.";
    };

    openFirewall = lib.mkEnableOption "open the firewall for the homelab-ollama TCP port";

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/run/secrets/homelab-ollama.env";
      description = ''
        Optional runtime environment file for systemd to load before starting
        the service. Use a normal filesystem path, not a Nix store path.
      '';
    };

    extraEnvironment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        JOBS_MAX_WORKERS = "2";
      };
      description = "Additional environment variables passed to homelab-ollama.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      systemd.services.homelab-ollama = {
        description = "homelab-ollama API service";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        path = [ cfg.ollamaPackage ];
        environment = {
          SERVICE_HOST = cfg.bindHost;
          SERVICE_PORT = toString cfg.port;
          STATE_DIR = "/var/lib/homelab-ollama";
          OLLAMA_EXE = lib.getExe cfg.ollamaPackage;
          OLLAMA_ARGS = "serve";
          OLLAMA_HOST = "127.0.0.1";
          OLLAMA_PORT = "11434";
          OLLAMA_PROCESS_NAME = "ollama";
          OLLAMA_REQUIRE_SERVE = "1";
          OLLAMA_STOP_SCOPE = "all";
          OLLAMA_STOP_TIMEOUT = "8";
          MAX_UPLOAD_MB = "50";
          JOBS_MAX_WORKERS = "1";
        } // cfg.extraEnvironment;
        serviceConfig =
          {
            DynamicUser = true;
            ExecStart = lib.getExe cfg.package;
            KillSignal = "SIGTERM";
            NoNewPrivileges = true;
            Restart = "on-failure";
            RestartSec = "5s";
            StandardError = "journal";
            StandardOutput = "journal";
            StateDirectory = "homelab-ollama";
            TimeoutStopSec = "30s";
            WorkingDirectory = "/var/lib/homelab-ollama";
          }
          // lib.optionalAttrs (cfg.environmentFile != null) {
            EnvironmentFile = cfg.environmentFile;
          };
      };
    }

    (lib.mkIf cfg.openFirewall {
      networking.firewall.allowedTCPPorts = [ cfg.port ];
    })
  ]);
}
