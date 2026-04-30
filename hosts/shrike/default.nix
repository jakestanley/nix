{ lib, profile, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./base
    ./base/desktop.nix
    ./base/greetd.nix
    ./base/plasma.nix
    ./base/nvidia.nix
    ./base/gaming.nix
    ./base/sleep-on-lan.nix
    ./base/reboot-to-windows.nix
    ../../modules/nixos/docker.nix
    ../../modules/nixos/home-manager.nix
    ../../modules/nixos/ssh.nix
    ./conditionals/sunshine.nix
    ./conditionals/display-sync.nix
    ./conditionals/steam-autostart.nix
    ./conditionals/xwayland-video-bridge.nix
    (./profiles + "/${profile}.nix")
  ];

  _module.args.activeProfile = profile;

  specialisation.tenfoot.configuration = {
    _module.args.activeProfile = lib.mkForce "tenfoot";
    imports = [ ./profiles/tenfoot.nix ];
  };
  specialisation.desktop.configuration = {
    _module.args.activeProfile = lib.mkForce "desktop";
    imports = [ ./profiles/desktop.nix ];
  };
  specialisation.gaming.configuration = {
    _module.args.activeProfile = lib.mkForce "gaming";
    imports = [ ./profiles/gaming.nix ];
  };

  system.stateVersion = "26.05";
}
