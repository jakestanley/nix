{ config, lib, pkgs, ... }:

let
  servicePort = import ../../sources/service-ports/arcade.nix;
  cfg = config.services.homelabArcade;
  defaultGameTcpPorts = [ 27015 ];
  defaultGameUdpPorts = [ 27015 27102 27131 ];
in
{
  options.services.homelabArcade = {
    enable = lib.mkEnableOption "homelab-arcade supervisor service";

    package = lib.mkPackageOption pkgs "homelab-arcade" { };

    user = lib.mkOption {
      type = lib.types.str;
      default = "arcade";
      example = "jake";
      description = "User account used to run homelab-arcade.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "arcade";
      example = "users";
      description = "Primary group used to run homelab-arcade.";
    };

    createUser = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether the module should create the configured system user and group.
        Disable this when running the service as an existing host user.
      '';
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = servicePort.port;
      description = "TCP port exposed by the arcade portal via PORTAL_PORT.";
    };

    configFile = lib.mkOption {
      type = lib.types.str;
      default = "/etc/arcade/config.yaml";
      example = "/etc/arcade/config.yaml";
      description = ''
        Host-managed config file passed via
        `HOMELAB_ARCADE_CONFIG_PATH`.
      '';
    };

    openFirewall = lib.mkEnableOption "open the firewall for the homelab-arcade portal port";

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/run/secrets/arcade.env";
      description = ''
        Optional runtime environment file for systemd to load before starting
        the service. Use a normal filesystem path, not a Nix store path.
      '';
    };

    extraEnvironment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        WEB_PORT = "5000";
      };
      description = "Additional environment variables passed to homelab-arcade.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (lib.mkIf cfg.createUser {
      users.groups.${cfg.group} = { };
      users.users.${cfg.user} = {
        isSystemUser = true;
        group = cfg.group;
        home = "/var/lib/homelab-arcade";
        createHome = false;
        description = "homelab-arcade service user";
      };
    })

    {
      systemd.tmpfiles.rules = [
        "d /etc/arcade 0750 root ${cfg.group} -"
      ];

      systemd.services.arcade = {
        description = "Homelab Arcade supervisor";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        environment = {
          PORTAL_PORT = toString cfg.port;
          XDG_CACHE_HOME = "/var/lib/homelab-arcade/.cache";
          PYTHONUNBUFFERED = "1";
          HOMELAB_ARCADE_CONFIG_PATH = cfg.configFile;
        }
        // cfg.extraEnvironment;
        serviceConfig =
          {
            User = cfg.user;
            Group = cfg.group;
            ExecStart = lib.getExe cfg.package;
            KillSignal = "SIGTERM";
            NoNewPrivileges = true;
            Restart = "on-failure";
            RestartSec = "5s";
            StandardError = "journal";
            StandardOutput = "journal";
            StateDirectory = "homelab-arcade";
            TimeoutStopSec = "30s";
            WorkingDirectory = "/var/lib/homelab-arcade";
          }
          // lib.optionalAttrs (cfg.environmentFile != null) {
            EnvironmentFile = cfg.environmentFile;
          };
      };
    }

    (lib.mkIf cfg.openFirewall {
      networking.firewall.allowedTCPPorts = [ cfg.port ] ++ defaultGameTcpPorts;
      networking.firewall.allowedUDPPorts = defaultGameUdpPorts;
    })
  ]);
}
