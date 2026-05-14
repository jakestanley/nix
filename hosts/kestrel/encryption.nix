{ pkgs, ... }:

{
  # fscrypt filesystem-level home directory encryption.
  # Enables the pam_fscrypt PAM module across login services so that
  # /home/work is unlocked transparently when jake logs in — no second
  # password prompt.
  #
  # NOTE: TPM2 binding is deferred to Phase 4. Until then, the user's
  # login passphrase is the only unlock method.
  #
  # Before first use, the ext4 encrypt feature must be enabled manually
  # on the nixos-kestrel partition (unmounted):
  #   tune2fs -O encrypt /dev/disk/by-label/nixos-kestrel
  # Then on first boot, run:
  #   sudo fscrypt setup
  #   sudo fscrypt encrypt /home/work --user=jake
  security.pam.enableFscrypt = true;

  # Block home-manager from running until /home/work is fscrypt-encrypted.
  # fscrypt status exits non-zero if the directory is not encrypted, which
  # prevents the service from populating an unencrypted home directory.
  systemd.services.home-manager-jake.serviceConfig.ExecCondition =
    "${pkgs.fscrypt-experimental}/bin/fscrypt status /home/work";
}
