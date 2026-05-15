# kestrel runs on the same physical machine as shrike.
# Hardware configuration is imported directly from shrike.
{ ... }:
{
  imports = [ ../shrike/hardware-configuration.nix ];

  # systemd-based initrd required for TPM2 LUKS unsealing via systemd-cryptsetup.
  boot.initrd.systemd.enable = true;

  boot.initrd.luks.devices."work" = {
    device = "/dev/disk/by-uuid/817ea6d0-01f1-4e25-907d-bba18fd4988d";
    # tpm2-device=auto: at boot, systemd-cryptsetup will attempt to unseal the
    # LUKS key from the TPM2 before falling back to a passphrase prompt.
    # One-time enrolment required on the machine after first deploy:
    #   systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 \
    #     /dev/disk/by-uuid/817ea6d0-01f1-4e25-907d-bba18fd4988d
    crypttabExtraOptions = [ "tpm2-device=auto" ];
  };

  fileSystems."/home/work" = {
    device = "/dev/mapper/work";
    fsType = "ext4";
    options = [ "defaults" "nofail" ];
  };
}
