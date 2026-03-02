{ config, lib, pkgs, ... }:

let
  servicePort = import ../../sources/service-ports/rtx.nix;
  cfg = config.services.rtx;
in
{
  options.services.rtx = {
    enable = lib.mkEnableOption "homelab-rtx GPU telemetry service";

    package = lib.mkPackageOption pkgs "homelab-rtx" { };

    bindHost = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      example = "127.0.0.1";
      description = "Bind host passed to homelab-rtx via RTX_BIND_HOST.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = servicePort.port;
      description = "TCP port exposed by homelab-rtx via RTX_PORT.";
    };

    openFirewall = lib.mkEnableOption "open the firewall for the homelab-rtx TCP port";

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/run/secrets/rtx.env";
      description = ''
        Optional runtime environment file for systemd to load before starting
        the service. Use a normal filesystem path, not a Nix store path.
      '';
    };

    extraEnvironment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        RTX_LOG_INTERVAL_SECONDS = "60";
      };
      description = "Additional environment variables passed to homelab-rtx.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      systemd.services.rtx = {
	description = "homelab-rtx GPU telemetry service";
	after = [ "network-online.target" ];
	wants = [ "network-online.target" ];
	wantedBy = [ "multi-user.target" ];
	path = [ config.hardware.nvidia.package ];
	environment = {
	  RTX_BIND_HOST = cfg.bindHost;
	  RTX_PORT = toString cfg.port;
	  RTX_LOG_PATH = "/var/lib/rtx/gpu-metrics.csv";
	  RTX_LOG_INTERVAL_SECONDS = "30";
	  RTX_QUERY_TIMEOUT_SECONDS = "5";
	} // cfg.extraEnvironment;
	serviceConfig =
	  {
	    DynamicUser = true;
	    ExecStart = lib.getExe cfg.package;
	    NoNewPrivileges = true;
	    Restart = "on-failure";
	    RestartSec = "5s";
	    StandardError = "journal";
	    StandardOutput = "journal";
	    StateDirectory = "rtx";
	    WorkingDirectory = "/var/lib/rtx";
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
