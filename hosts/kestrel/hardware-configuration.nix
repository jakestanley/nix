# kestrel runs on the same physical machine as shrike.
# Hardware configuration is imported directly from shrike.
{ ... }:
{
  imports = [ ../shrike/hardware-configuration.nix ];

  boot.initrd.luks.devices."work" = {
    device = "/dev/disk/by-uuid/817ea6d0-01f1-4e25-907d-bba18fd4988d";
  };

  fileSystems."/home/work" = {
    device = "/dev/mapper/work";
    fsType = "ext4";
    options = [ "defaults" "nofail" ];
  };
}
