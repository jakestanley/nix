{ config, lib, pkgs, ... }:

let
  cfg = config.services.sleepOnLan;
  jsonFormat = pkgs.formats.json { };

  generatedConfig =
    jsonFormat.generate "sleep-on-lan.json" ({
      Listeners = cfg.listeners;
    } // cfg.extraSettings);

  effectiveConfigFile =
    if cfg.configFile != null then cfg.configFile else generatedConfig;

  parseListener = listener:
    let
      parts = lib.splitString ":" listener;
      kind = lib.toUpper (builtins.elemAt parts 0);
      port =
        if builtins.length parts == 2 then
          builtins.fromJSON (builtins.elemAt parts 1)
        else if kind == "UDP" then
          9
        else
          8009;
    in {
      inherit kind port;
    };

  parsedListeners = map parseListener cfg.listeners;
  firewallUdpPorts = lib.unique (map (listener: listener.port) (builtins.filter (listener: listener.kind == "UDP") parsedListeners));
  firewallTcpPorts = lib.unique (map (listener: listener.port) (builtins.filter (listener: listener.kind == "HTTP") parsedListeners));
in
{
  options.services.sleepOnLan = {
    enable = lib.mkEnableOption "Sleep-On-LAN daemon";

    package = lib.mkPackageOption pkgs "sleep-on-lan" { };

    listeners = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "UDP:9" "HTTP:8009" ];
      example = [ "UDP:9" "HTTP:18009" ];
      description = ''
        Listener definitions passed through the generated Sleep-On-LAN JSON
        configuration. Use values such as `UDP:9` or `HTTP:8009`.
      '';
    };

    openFirewall = lib.mkEnableOption "open the firewall for the configured Sleep-On-LAN listeners";

    configFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/run/secrets/sleep-on-lan.json";
      description = ''
        Optional runtime JSON configuration file. Use a normal filesystem path,
        not a Nix store path. When set, `listeners` and `extraSettings` are not
        rendered into a generated store-backed config file.
      '';
    };

    extraSettings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      example = {
        BroadcastIP = "192.168.1.255";
        ExitIfAnyPortIsAlreadyUsed = true;
      };
      description = ''
        Additional Sleep-On-LAN JSON settings merged into the generated
        configuration file.
      '';
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "--verbose" ];
      description = "Additional command-line arguments passed to the daemon.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      systemd.services.sleep-on-lan = {
        description = "Sleep-On-LAN daemon";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];

        # The daemon must be able to bind low UDP ports and execute the system
        # suspend command, so it intentionally runs as root.
        serviceConfig = {
          ExecStart = lib.escapeShellArgs ([ (lib.getExe cfg.package) "--config" effectiveConfigFile ] ++ cfg.extraArgs);
          Group = "root";
          NoNewPrivileges = true;
          PrivateTmp = true;
          Restart = "on-failure";
          RestartSec = "5s";
          StandardError = "journal";
          StandardOutput = "journal";
          StateDirectory = "sleep-on-lan";
          User = "root";
          WorkingDirectory = "/var/lib/sleep-on-lan";
        };
      };
    }

    (lib.mkIf cfg.openFirewall {
      networking.firewall.allowedTCPPorts = firewallTcpPorts;
      networking.firewall.allowedUDPPorts = firewallUdpPorts;
    })
  ]);
}
