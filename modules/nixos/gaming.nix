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
  };

  programs.gamemode.enable = true;

  hardware.graphics.enable32Bit = true;

  environment.systemPackages = [ pkgs.mangohud ];

  users.groups.jake = { };
  users.users.jake.extraGroups = [ "jake" ];

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
