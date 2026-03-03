{ lib, pkgs, ... }:

let
  demucsCuda = pkgs.python3.withPackages (ps: [
    ps.demucs
    ps.pytorchWithCuda
  ]);
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

  environment.systemPackages = [
    demucsCuda
    pkgs.ollama-cuda
  ];

  services.homelabDemucs.enable = true;
  services.homelabDemucs.openFirewall = true;
  services.homelabDemucs.package = pkgs.homelab-demucs.override {
    torchPackage = pkgs.python3Packages.pytorchWithCuda;
  };
  services.homelabDemucs.demucsPackage = demucsCuda;

  services.homelabOllama.enable = true;
  services.homelabOllama.openFirewall = true;
  services.homelabOllama.ollamaPackage = pkgs.ollama-cuda;

  # Hosts opt into the reusable RTX module declaratively here.
  services.rtx.enable = true;
  services.rtx.openFirewall = true;

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
