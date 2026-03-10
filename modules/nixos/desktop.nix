{ pkgs, ... }:

{
  imports = [
    ./base.nix
  ];

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  programs.firefox.enable = true;

  users.users.jake.packages = with pkgs; [
    kdePackages.kate
  ];

  environment.systemPackages = with pkgs; [
    spotify
    kdePackages.kdialog
  ];
}
