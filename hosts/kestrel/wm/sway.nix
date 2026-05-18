{ pkgs, ... }:

{
  imports = [
    ../../modules/nixos/nvidia.nix
  ];

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command =
          let
            # --unsupported-gpu required for proprietary NVIDIA driver.
            # Wrapped in a script so greetd execs a single binary, not a string with args.
            startSway = pkgs.writeShellScript "start-sway" ''
              exec sway --unsupported-gpu
            '';
          in
          "${pkgs.tuigreet}/bin/tuigreet --time --cmd ${startSway}";
        user = "greeter";
      };
    };
  };

  # pam_fscrypt needs to lock key material in memory; raise the limit for greetd.
  systemd.services.greetd.serviceConfig.LimitMEMLOCK = "infinity";

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  environment.systemPackages = [
    pkgs.swaylock
    pkgs.swayidle
    pkgs.waybar
    pkgs.wofi
    pkgs.alacritty
    pkgs.wl-clipboard
    pkgs.brightnessctl
    pkgs.playerctl
    pkgs.grim
    pkgs.slurp

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
