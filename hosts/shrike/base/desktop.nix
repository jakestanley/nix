{ pkgs, activeProfile, ... }:

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

  programs.firefox.enable = activeProfile != "tenfoot";

  users.users.jake.packages = pkgs.lib.optionals (activeProfile != "tenfoot") (with pkgs; [
    kdePackages.kate
  ]);

  environment.systemPackages = pkgs.lib.optionals (activeProfile != "tenfoot") (with pkgs; [
    spotify
    kdePackages.kdialog
  ]);
}
