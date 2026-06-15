{ pkgs, ... }:

let
  displaySync = pkgs.writers.writePython3Bin "display-sync" { } (
    builtins.readFile ../scripts/display-sync.py
  );
in
{
  imports = [
    ../../../modules/nixos/base.nix
  ];

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.extraConfig."10-keep-hdmi-alive" = {
      "monitor.alsa.rules" = [
        {
          matches = [ { "node.name" = "~alsa_output.pci*hdmi*"; } ];
          actions.update-props = {
            "session.suspend-timeout-seconds" = 0;
          };
        }
      ];
    };
  };

  programs.firefox.enable = true;

  users.users.jake.packages = with pkgs; [
    kdePackages.kate
  ];

  environment.systemPackages = with pkgs; [
    spotify
    kdePackages.kdialog
    displaySync
    kdePackages.libkscreen
  ];

  systemd.user.services.display-sync = {
    enable = true;
    description = "Auto toggle HDMI outputs based on DisplayPort state";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${displaySync}/bin/display-sync";
      Restart = "always";
      RestartSec = 3;
      Environment = [
        "PATH=/run/current-system/sw/bin:/usr/bin:/bin"
        "WAYLAND_DISPLAY=wayland-0"
      ];
    };
  };

  services.sunshine = {
    enable = true;
    package = pkgs.sunshine.override {
      cudaSupport = true;
    };
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };
}
