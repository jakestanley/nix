{ pkgs, ... }:

let
  geProtonVersion = "GE-Proton10-32";
  geProton = pkgs.stdenvNoCC.mkDerivation {
    pname = "ge-proton";
    version = geProtonVersion;

    src = pkgs.fetchurl {
      url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${geProtonVersion}/${geProtonVersion}.tar.gz";
      sha256 = "sha256-Cw0/2e1HfN9wWibN47iK+xk5L7EzDQS3+kTTmhtIxts=";
    };

    nativeBuildInputs = [
      pkgs.gnutar
      pkgs.gzip
    ];

    dontConfigure = true;
    dontBuild = true;

    outputs = [
      "out"
      "steamcompattool"
    ];

    unpackPhase = ''
      runHook preUnpack
      mkdir source
      tar -xzf "$src" -C source
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p "$out" "$steamcompattool"
      cp -a "source/${geProtonVersion}/." "$out/"
      cp -a "source/${geProtonVersion}/." "$steamcompattool/"
      runHook postInstall
    '';
  };

in
{
  # Specialisations are layered on top of the default system. Any long-lived
  # service that must not run in gaming mode should be disabled from the host's
  # specialisation block with `lib.mkForce false`.
  programs.steam = {
    enable = true;
    extraCompatPackages = [ geProton ];
    extraPackages = [
      pkgs.gamemode
      pkgs.mangohud
    ];
  
    gamescopeSession.enable = true;

    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server  
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers

    package = pkgs.steam.override {
      extraArgs = "-pipewire";
      extraEnv = {
        MANGOHUD= "1";
        # run mangohud but don't display initially, i.e you're streaming to a 10foot
        MANGOHUD_CONFIG = "read_cfg,no_display";
        # this doesn't work so you'll still have to add gamemoderun %command% to every game for now
        #GAMEMODERUN = "1";
      };
    };
  };

  programs.gamemode.enable = true;

  boot.kernel.sysctl."vm.max_map_count" = 2147483642;

  hardware.graphics.enable32Bit = true;

  # enable controllers with udev rules
  hardware.steam-hardware.enable = true;
  
  # xbox controller driver?
  hardware.xpadneo.enable = true;

  environment.systemPackages = [
    pkgs.mangohud
    # some actual games
    pkgs.dsda-doom
    pkgs.dsda-launcher
    pkgs.prismlauncher
    pkgs.shipwright
  ];

  users.groups.jake = { };
  users.users.jake.extraGroups = [ "jake" "gamemode" ];

  systemd.user.services.steam-autostart = {
    enable = true;
    description = "Start Steam when the graphical session starts";
    # Steam must start AFTER the xdg-desktop-portal ScreenCast backend and
    # PipeWire are ready. If Steam wins the race it decides the portal is
    # unavailable and silently uses X11/xcomposite capture for the whole
    # session, which renders streamed (composited Xwayland) game windows as a
    # black frame. Starting after the portal lets Steam take the PipeWire
    # output-capture path, which streams games correctly.
    after = [
      "graphical-session.target"
      "xdg-desktop-portal.service"
      "plasma-xdg-desktop-portal-kde.service"
      "pipewire.service"
      "wireplumber.service"
    ];
    wants = [
      "xdg-desktop-portal.service"
      "plasma-xdg-desktop-portal-kde.service"
      "pipewire.service"
    ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Environment = "PATH=/run/current-system/sw/bin:/usr/bin:/bin";
      # The portal is D-Bus activated, so unit ordering alone isn't enough.
      # Wait until the ScreenCast interface actually answers on the bus before
      # launching Steam. Times out after ~30s so Steam still starts regardless.
      ExecStartPre = pkgs.writeShellScript "wait-for-screencast-portal" ''
        for _ in $(seq 1 30); do
          if ${pkgs.systemd}/bin/busctl --user introspect \
              org.freedesktop.portal.Desktop \
              /org/freedesktop/portal/desktop \
              org.freedesktop.portal.ScreenCast >/dev/null 2>&1; then
            exit 0
          fi
          sleep 1
        done
        exit 0
      '';
      ExecStart = "${pkgs.steam}/bin/steam -silent -pipewire";
    };
  };

  systemd.tmpfiles.settings."10-gaming" = {
    "/home/jake/.steam".d = {
      mode = "0755";
      user = "jake";
      group = "jake";
    };

    "/home/jake/.steam/root".d = {
      mode = "0755";
      user = "jake";
      group = "jake";
    };

    "/home/jake/.steam/root/compatibilitytools.d".d = {
      mode = "0755";
      user = "jake";
      group = "jake";
    };

    "/home/jake/.steam/root/compatibilitytools.d/GE-Proton"."L+" = {
      argument = "${geProton.steamcompattool}";
    };

    "/home/jake/.local/share/Steam/compatibilitytools.d".d = {
      mode = "0755";
      user = "jake";
      group = "users";
    };

    "/home/jake/.local/share/Steam/compatibilitytools.d/GE-Proton"."L+" = {
      argument = "${geProton.steamcompattool}";
    };
  };
}
