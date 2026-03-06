{ config, lib, pkgs, ... }:

let
  servicePort = import ../../sources/service-ports/demucs.nix;
  cfg = config.services.homelabDemucs;
  demucsExecutableLooksLikePath = lib.hasPrefix "/" cfg.demucsExecutable;
  demucsExecutableLooksLikeCommand = builtins.match "^[A-Za-z0-9._+-]+$" cfg.demucsExecutable != null;
  executableCheckScript = pkgs.writeShellScript "homelab-demucs-check-executable" ''
    set -euo pipefail
    target=${lib.escapeShellArg cfg.demucsExecutable}

    if [[ "$target" = /* ]]; then
      if [[ ! -x "$target" ]]; then
        echo "homelab-demucs: demucs executable is not executable: $target" >&2
        exit 1
      fi
    elif ! command -v "$target" >/dev/null 2>&1; then
      echo "homelab-demucs: demucs executable not found in PATH: $target" >&2
      exit 1
    fi
  '';
in
{
  options.services.homelabDemucs = {
    enable = lib.mkEnableOption "homelab-demucs separation service";

    package = lib.mkPackageOption pkgs "homelab-demucs" { };

    demucsExecutable = lib.mkOption {
      type = lib.types.str;
      default = "demucs";
      example = "${pkgs.demucsCuda}/bin/demucs";
      description = ''
        Executable used by homelab-demucs for separation jobs. This is managed
        outside the homelab-demucs service module.
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

    device = lib.mkOption {
      type = lib.types.str;
      default = "cuda";
      example = "cuda";
      description = ''
        Device string passed to homelab-demucs via `DEMUCS_DEVICE`.
        No automatic CPU fallback is applied by this module.
      '';
    };

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

    runtimePackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ pkgs.ffmpeg ];
      description = ''
        Runtime packages added to PATH for the service process. This can include
        a Demucs package when you want the service to resolve `demucs` by name.
      '';
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions = [
        {
          assertion = demucsExecutableLooksLikePath || demucsExecutableLooksLikeCommand;
          message = "services.homelabDemucs.demucsExecutable must be an absolute path or a simple command name.";
        }
        {
          assertion = demucsExecutableLooksLikePath || (cfg.runtimePackages != [ ]);
          message = "services.homelabDemucs.demucsExecutable is not absolute; set runtimePackages so the executable can be resolved in PATH.";
        }
      ];
    }

    {
      systemd.services.homelab-demucs = {
        description = "homelab-demucs separation API service";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        path = cfg.runtimePackages;
        environment = {
          HOST = cfg.bindHost;
          PORT = toString cfg.port;
          STORAGE_ROOT = "/var/lib/homelab-demucs";
          HOME = "/var/lib/homelab-demucs";
          XDG_CACHE_HOME = "/var/lib/homelab-demucs/.cache";
          MAX_CONCURRENT_JOBS = "1";
          DEMUCS_DEFAULT_MODEL = "htdemucs";
          DEMUCS_MODELS = "htdemucs,htdemucs_ft,mdx,mdx_q";
          DEMUCS_BIN = cfg.demucsExecutable;
          DEMUCS_DEVICE = cfg.device;
          JOB_TIMEOUT_SECONDS = "180";
          OUTPUT_FORMAT_VERSION = "v1-wav";
        } // cfg.extraEnvironment;
        serviceConfig =
          {
            DynamicUser = true;
            ExecStartPre = executableCheckScript;
            ExecStart = lib.getExe cfg.package;
            KillSignal = "SIGTERM";
            NoNewPrivileges = true;
            Restart = "on-failure";
            RestartSec = "5s";
            StandardError = "journal";
            StandardOutput = "journal";
            StateDirectory = "homelab-demucs";
            TimeoutStopSec = "30s";
            WorkingDirectory = "/var/lib/homelab-demucs";
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
