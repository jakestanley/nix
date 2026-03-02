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

  mangoHudConfig = pkgs.writeText "MangoHud.conf" ''
    toggle_hud=F10
    fps
    frametime
    cpu_temp
    gpu_temp
    cpu_load
    gpu_load
  '';
in
{
  programs.steam = {
    enable = true;
    extraCompatPackages = [ geProton ];
    extraPackages = [
      pkgs.gamemode
      pkgs.mangohud
    ];
  };

  programs.gamemode.enable = true;

  hardware.graphics.enable32Bit = true;

  environment.systemPackages = [ pkgs.mangohud ];

  users.groups.jake = { };
  users.users.jake.extraGroups = [ "jake" ];

  systemd.tmpfiles.settings."10-gaming" = {
    "/home/jake/.config/MangoHud".d = {
      mode = "0755";
      user = "jake";
      group = "jake";
    };

    "/home/jake/.config/MangoHud/MangoHud.conf"."L+" = {
      argument = "${mangoHudConfig}";
    };

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
  };
}
