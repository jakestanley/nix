{ config, lib, pkgs, ... }:

let
  demucsServiceEnabled = true;
  publicKeys = (import ../../modules/nixos/public-keys.nix {}).publicKeys;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/docker.nix
    ../../modules/nixos/home-manager.nix
    ../../modules/nixos/ssh.nix
    ../../modules/nixos/plasma.nix
    ../../modules/nixos/greetd-autologin.nix
    ../../modules/nixos/cs2-dedicated.nix
    ../../modules/nixos/homelab-demucs.nix
    ../../modules/nixos/homelab-ollama.nix
    ../../modules/nixos/nvidia.nix
    ../../modules/nixos/sunshine.nix
    ../../modules/nixos/gaming.nix
    ../../modules/nixos/rtx.nix
    ../../modules/nixos/sleep-on-lan.nix
    ../../modules/nixos/reboot-to-windows.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "max";
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "shrike";

  users.users.jake.openssh.authorizedKeys.keys = [
    publicKeys.turing
    publicKeys.adler
  ];

  home-manager.extraSpecialArgs = {
    hostname = "shrike";
  };

  # Favor one large local build over many competing derivations when compiling
  # heavy packages such as ollama-cuda.
  nix.settings = {
    max-jobs = 1;
    cores = 0;
  };

  systemd.services.wake-on-lan-enp4s0 = {
    description = "Enable wake-on-LAN on enp4s0";
    after = [ "NetworkManager.service" ];
    wants = [ "NetworkManager.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.ethtool}/bin/ethtool -s enp4s0 wol g";
    };
  };

  # homelab self signed cert
  security.pki.certificateFiles = [ ../../ca.crt ];

  environment.systemPackages =
    lib.optionals config.services.homelabDemucs.enable [ config.services.homelabDemucs.demucsPackage ]
    ++ [
      pkgs.ollama-cuda
      pkgs.vscode
      # TODO make this a common package
      pkgs.duf
    ];

  services.homelabDemucs.enable = demucsServiceEnabled;
  services.homelabDemucs.openFirewall = demucsServiceEnabled;

  services.cs2Dedicated = {
    enable = true;
    openFirewall = true;
    user = "jake";
    group = "users";
    bindIp = "10.92.8.4";
    port = 27015;
    maxPlayers = 64;
    steamRoot = "/home/jake/.local/share/Steam";
    cs2Path = "/home/jake/.local/share/Steam/steamapps/common/Counter-Strike Global Offensive";
    rconPasswordFile = "/etc/arcade/rcon_password";
    gsltTokenFile = "/etc/arcade/gslt_token";
    extraLibraryPaths = [ "/home/jake/.steam/sdk64" ];
    startupCvars = {
      game_alias = "competitive";
      map = "de_dust2";
    };
  };

  services.homelabOllama.enable = true;
  services.homelabOllama.openFirewall = true;
  services.homelabOllama.ollamaPackage = pkgs.ollama-cuda;

  # Hosts opt into the reusable RTX module declaratively here.
  services.rtx.enable = true;
  services.rtx.openFirewall = true;

  services.sleepOnLan.enable = true;
  services.sleepOnLan.openFirewall = true;

  specialisation.gaming.configuration = {
    # Long-lived systemd units stay enabled in the default system and are
    # explicitly forced off here when the gaming boot entry must not run them.
    services.homelabDemucs.enable = lib.mkForce false;
    services.homelabOllama.enable = lib.mkForce false;
    services.rtx.enable = lib.mkForce false;
    services.sunshine.enable = lib.mkForce false;
    virtualisation.docker.enable = lib.mkForce false;
  };

  system.stateVersion = "26.05";
}
