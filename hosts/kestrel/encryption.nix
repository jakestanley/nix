{ pkgs, ... }:

{
  # fscrypt filesystem-level home directory encryption.
  # Enables the pam_fscrypt PAM module across login services so that
  # /home/work is unlocked transparently when jake logs in — no second
  # password prompt.
  #
  # NOTE: TPM2 binding is deferred to Phase 4. Until then, the user's
  # login passphrase is the only unlock method.
  security.pam.enableFscrypt = true;
  security.pam.services.greetd.enableFscrypt = true;

  # Enable the ext4 encrypt feature on the root filesystem if not already set.
  # Required once before fscrypt can encrypt any directories.
  # Idempotent — safe to run on every activation.
  system.activationScripts.enableFscryptOnRoot = ''
    dev=$(${pkgs.util-linux}/bin/findmnt -n -o SOURCE /)
    if ! ${pkgs.e2fsprogs}/bin/tune2fs -l "$dev" 2>/dev/null | grep -q encrypt; then
      ${pkgs.e2fsprogs}/bin/tune2fs -O encrypt "$dev"
    fi
  '';
}
