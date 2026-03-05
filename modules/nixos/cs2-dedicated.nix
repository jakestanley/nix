{ config, lib, pkgs, ... }:

let
  cfg = config.services.cs2Dedicated;
  rconPackage = pkgs.python3Packages.rcon or (pkgs.python3Packages.callPackage ../../pkgs/rcon { });
  rconPython = pkgs.python3.withPackages (_: [ rconPackage ]);
  cs2Binary = "${cfg.cs2Path}/game/bin/linuxsteamrt64/cs2";
  cvarValueToString = value:
    if builtins.isBool value then
      (if value then "1" else "0")
    else
      toString value;
  startupCvarArgs = lib.concatMapStringsSep " " (name:
    "+${name} ${lib.escapeShellArg (cvarValueToString cfg.startupCvars.${name})}"
  ) (lib.attrNames cfg.startupCvars);
  rconPasswordFileValue = if cfg.rconPasswordFile == null then "" else cfg.rconPasswordFile;

  preflightScript = pkgs.writeShellScript "cs2-dedicated-preflight" ''
    set -euo pipefail

    if [[ ! -x ${lib.escapeShellArg cs2Binary} ]]; then
      echo "cs2-dedicated: executable not found: ${cs2Binary}" >&2
      exit 1
    fi
  '';

  launchScript = pkgs.writeShellScript "cs2-dedicated-launch" ''
    set -euo pipefail

    rcon_password="''${RCON_PASSWORD:-}"
    rcon_password_file=${lib.escapeShellArg rconPasswordFileValue}
    if [[ -z "$rcon_password" && -n "$rcon_password_file" && -r "$rcon_password_file" ]]; then
      rcon_password="$(<"$rcon_password_file")"
    fi

    rcon_args=()
    if [[ -n "$rcon_password" ]]; then
      rcon_args=(+rcon_password "$rcon_password")
    elif [[ "${if cfg.requireRconPassword then "1" else "0"}" == "1" ]]; then
      echo "cs2-dedicated: no RCON secret provided; refusing to start (set RCON_PASSWORD or configure services.cs2Dedicated.rconPasswordFile)." >&2
      exit 1
    else
      echo "cs2-dedicated: starting without +rcon_password (no RCON secret provided)." >&2
    fi

    export LD_LIBRARY_PATH=${lib.escapeShellArg (lib.concatStringsSep ":" ([
      "${cfg.cs2Path}/game/bin/linuxsteamrt64"
      "${cfg.steamRoot}/linux64"
      "${cfg.steamRoot}/ubuntu12_64"
    ] ++ cfg.extraLibraryPaths))}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}

    exec ${lib.getExe cfg.execWrapperPackage} ${lib.escapeShellArg cs2Binary} \
      -dedicated \
      -ip ${lib.escapeShellArg cfg.bindIp} \
      -port ${toString cfg.port} \
      -maxplayers ${toString cfg.maxPlayers} \
      ${lib.escapeShellArgs cfg.startupFlags} \
      ${startupCvarArgs} \
      "''${rcon_args[@]}"
  '';

  rconScript = pkgs.writeShellScriptBin "cs2-rcon" ''
    set -euo pipefail

    if [[ "$#" -lt 1 ]]; then
      echo "usage: cs2-rcon <rcon command...>" >&2
      exit 2
    fi

    password="''${RCON_PASSWORD:-}"
    password_file=${lib.escapeShellArg rconPasswordFileValue}
    if [[ -z "$password" && -n "$password_file" && -r "$password_file" ]]; then
      password="$(<"$password_file")"
    fi

    if [[ -z "$password" ]]; then
      echo "cs2-rcon: no RCON password available (set RCON_PASSWORD or configure services.cs2Dedicated.rconPasswordFile)." >&2
      exit 1
    fi

    export CS2_RCON_HOST=${lib.escapeShellArg cfg.rconHost}
    export CS2_RCON_PORT=${toString cfg.port}
    export CS2_RCON_PASSWORD="$password"
    exec ${rconPython}/bin/python - "$@" <<'PY'
import os
import sys

from rcon.source import Client

host = os.environ["CS2_RCON_HOST"]
port = int(os.environ["CS2_RCON_PORT"])
password = os.environ["CS2_RCON_PASSWORD"]
command = " ".join(sys.argv[1:])

with Client(host, port, passwd=password) as client:
    result = client.run(command)

if result is not None:
    print(result)
PY
  '';
in
{
  options.services.cs2Dedicated = {
    enable = lib.mkEnableOption "Counter-Strike 2 dedicated server";

    user = lib.mkOption {
      type = lib.types.str;
      default = "jake";
      description = "User account used to run the CS2 dedicated process.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "users";
      description = "Primary group used to run the CS2 dedicated process.";
    };

    steamRoot = lib.mkOption {
      type = lib.types.str;
      default = "/home/jake/.local/share/Steam";
      description = "Steam root directory that contains runtime libraries.";
    };

    cs2Path = lib.mkOption {
      type = lib.types.str;
      default = "/home/jake/.local/share/Steam/steamapps/common/Counter-Strike Global Offensive";
      description = "CS2 installation root directory.";
    };

    execWrapperPackage = lib.mkPackageOption pkgs "steam-run" { };

    bindIp = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "Bind IP address passed to CS2 via -ip.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 27015;
      description = "Game and RCON port passed to CS2 via -port.";
    };

    maxPlayers = lib.mkOption {
      type = lib.types.int;
      default = 64;
      description = "Maximum player slots passed to CS2 via -maxplayers.";
    };

    startupFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "-usercon" "-strictportbind" "-nomaster" "-high" ];
      description = "Additional CS2 startup flags.";
    };

    startupCvars = lib.mkOption {
      type = lib.types.attrsOf (lib.types.oneOf [
        lib.types.str
        lib.types.int
        lib.types.float
        lib.types.bool
      ]);
      default = {
        game_alias = "competitive";
        map = "de_dust2";
      };
      description = ''
        Startup cvars rendered as `+<name> <value>` arguments in deterministic
        attribute-name order.
      '';
    };

    rconHost = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Default host used by the cs2-rcon helper.";
    };

    rconPasswordFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/run/secrets/cs2-rcon-password";
      description = ''
        Optional runtime path that stores the RCON password as plain text.
        If `RCON_PASSWORD` is present in `environmentFile`, it takes precedence.
      '';
    };

    requireRconPassword = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Require an RCON password at startup. When enabled, service startup
        fails unless `RCON_PASSWORD` or `rconPasswordFile` is provided.
      '';
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/run/secrets/cs2.env";
      description = ''
        Optional runtime environment file loaded by systemd before start.
        Supported key: `RCON_PASSWORD`.
      '';
    };

    extraLibraryPaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra paths appended into LD_LIBRARY_PATH before starting CS2.";
    };

    openFirewall = lib.mkEnableOption "open the firewall for the CS2 game port";

    extraFirewallTcpPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [ ];
      description = "Additional TCP ports opened when openFirewall is enabled.";
    };

    extraFirewallUdpPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [ 27102 27131 ];
      description = "Additional UDP ports opened when openFirewall is enabled.";
    };

    installRconCli = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install the `cs2-rcon` helper script into system packages.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      systemd.services.cs2-dedicated = {
        description = "Counter-Strike 2 dedicated server";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig =
          {
            User = cfg.user;
            Group = cfg.group;
            ExecStartPre = preflightScript;
            ExecStart = launchScript;
            KillSignal = "SIGTERM";
            NoNewPrivileges = true;
            Restart = "on-failure";
            RestartSec = "5s";
            StandardError = "journal";
            StandardOutput = "journal";
            TimeoutStopSec = "30s";
            WorkingDirectory = cfg.cs2Path;
          }
          // lib.optionalAttrs (cfg.environmentFile != null) {
            EnvironmentFile = cfg.environmentFile;
          };
      };
    }

    (lib.mkIf cfg.installRconCli {
      environment.systemPackages = [ rconScript ];
    })

    (lib.mkIf cfg.openFirewall {
      networking.firewall.allowedTCPPorts = [ cfg.port ] ++ cfg.extraFirewallTcpPorts;
      networking.firewall.allowedUDPPorts = [ cfg.port ] ++ cfg.extraFirewallUdpPorts;
    })
  ]);
}
