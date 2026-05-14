{ pkgs, ... }:

{
  imports = [
    ../../modules/nixos/nvidia.nix
  ];

  services.xserver = {
    enable = true;
    displayManager.lightdm.enable = true;
    # i3-gaps was merged into i3 upstream; i3 now includes gap support natively
    windowManager.i3.enable = true;
  };

  environment.systemPackages = [
    pkgs.i3
    pkgs.i3status
    pkgs.i3lock
    pkgs.rofi
    pkgs.polybar
    pkgs.alacritty
    pkgs.feh
    pkgs.picom
    pkgs.xclip
    pkgs.brightnessctl
    pkgs.playerctl

    # Switch to shrike boot entry and reboot
    (pkgs.writeShellScriptBin "switch-to-gaming" ''
      entry=$(bootctl list --json=short 2>/dev/null | ${pkgs.jq}/bin/jq -r '.[] | select(.title | test("shrike"; "i")) | .id' | head -1)
      if [ -z "$entry" ]; then
        echo "No shrike boot entry found" >&2
        exit 1
      fi
      echo "Switching to boot entry: $entry"
      sudo bootctl set-oneshot "$entry"
      sudo reboot
    '')
  ];
}
