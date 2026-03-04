{ lib, pkgs, ... }:

let
  torchBin = pkgs.python3Packages.torch-bin.overrideAttrs (_: {
    dontCheckRuntimeDeps = true;
  });
  torchaudioBin = pkgs.python3Packages.torchaudio-bin.override {
    "torch-bin" = torchBin;
  };
  demucsCuda = pkgs.demucs.override {
    torchPackage = torchBin;
    torchaudioPackage = torchaudioBin;
  };
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
    ../../modules/nixos/gaming.nix
    ../../modules/nixos/rtx.nix
    ../../modules/nixos/sleep-on-lan.nix
    ../../modules/nixos/reboot-to-windows.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "max";
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos";

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

  environment.systemPackages = [
    demucsCuda
    pkgs.ollama-cuda
  ];

  services.homelabDemucs.enable = true;
  services.homelabDemucs.openFirewall = true;
  services.homelabDemucs.package = pkgs.homelab-demucs.override {
    torchPackage = torchBin;
  };
  services.homelabDemucs.demucsPackage = demucsCuda;

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
    virtualisation.docker.enable = lib.mkForce false;
  };

  system.stateVersion = "26.05";
}
