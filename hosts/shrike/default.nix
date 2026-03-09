{ config, lib, pkgs, ... }:

let
  demucsServiceEnabled = true;
  publicKeys = (import ../../modules/nixos/public-keys.nix {}).publicKeys;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/base.nix
    ../../modules/nixos/docker.nix
    ../../modules/nixos/home-manager.nix
    ../../modules/nixos/ssh.nix
    ../../modules/nixos/plasma.nix
    ../../modules/nixos/greetd-autologin.nix
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

  environment.systemPackages =
    lib.optionals config.services.homelabDemucs.enable [ config.services.homelabDemucs.demucsPackage ]
    ++ [
      pkgs.ollama-cuda
    ];

  services.homelabDemucs.enable = demucsServiceEnabled;
  services.homelabDemucs.openFirewall = demucsServiceEnabled;

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
