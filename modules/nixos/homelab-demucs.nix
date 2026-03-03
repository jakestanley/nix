{ config, lib, pkgs, ... }:

let
  servicePort = import ../../sources/service-ports/demucs.nix;
  cfg = config.services.homelabDemucs;
  demucsExecutable =
    if cfg.demucsPackage == null then "demucs"
    else lib.getExe cfg.demucsPackage;
in
{
  options.services.homelabDemucs = {
    enable = lib.mkEnableOption "homelab-demucs separation service";

    package = lib.mkPackageOption pkgs "homelab-demucs" { };

    demucsPackage = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      example = lib.literalExpression "pkgs.python3Packages.demucs";
      description = ''
        Optional package providing the `demucs` CLI. When unset, the service
        expects `demucs` to already be available on PATH.
      '';
    };

    bindHost = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      example = "127.0.0.1";
      description = "Bind host passed to homelab-demucs via HOST.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = servicePort.port;
      description = "TCP port exposed by homelab-demucs via PORT.";
    };

    openFirewall = lib.mkEnableOption "open the firewall for the homelab-demucs TCP port";

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/run/secrets/demucs.env";
      description = ''
        Optional runtime environment file for systemd to load before starting
        the service. Use a normal filesystem path, not a Nix store path.
      '';
    };

    extraEnvironment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        MAX_CONCURRENT_JOBS = "2";
      };
      description = "Additional environment variables passed to homelab-demucs.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      systemd.services.demucs = {
        description = "Demucs separation API service";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        path = lib.optionals (cfg.demucsPackage != null) [ cfg.demucsPackage ];
        environment = {
          HOST = cfg.bindHost;
          PORT = toString cfg.port;
          STORAGE_ROOT = "/var/lib/demucs";
          MAX_CONCURRENT_JOBS = "1";
          DEMUCS_DEFAULT_MODEL = "htdemucs";
          DEMUCS_MODELS = "htdemucs,htdemucs_ft,mdx,mdx_q";
          DEMUCS_BIN = demucsExecutable;
          DEMUCS_DEVICE = "cuda";
          JOB_TIMEOUT_SECONDS = "180";
          OUTPUT_FORMAT_VERSION = "v1-wav";
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
            StateDirectory = "demucs";
            TimeoutStopSec = "30s";
            WorkingDirectory = "/var/lib/demucs";
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
