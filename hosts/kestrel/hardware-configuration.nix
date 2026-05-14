# kestrel runs on the same physical machine as shrike.
# Hardware configuration is imported directly from shrike.
{ ... }:
{
  imports = [ ../shrike/hardware-configuration.nix ];

  fileSystems."/home/work" = {
    device = "/dev/disk/by-label/nixos-kestrel";
    fsType = "ext4";
    options = [ "defaults" "nofail" "x-systemd.automount" "noauto" ];
  };
}
