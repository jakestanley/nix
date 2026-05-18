{ pkgs, ... }:

{
  imports = [
    ../../modules/nixos/nvidia.nix
  ];

  services.desktopManager.plasma6.enable = true;
  services.xserver.xkb = {
    layout = "gb";
    variant = "";
  };

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa
    spectacle
    gwenview
    okular
    discover
    ark
    khelpcenter
    krdp
  ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  environment.systemPackages = [
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
