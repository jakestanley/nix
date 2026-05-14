{ ... }:

{
  # fscrypt filesystem-level home directory encryption.
  # Enables the pam_fscrypt PAM module across login services so that
  # /home/work is unlocked transparently when jake logs in — no second
  # password prompt.
  #
  # NOTE: TPM2 binding is deferred to Phase 4. Until then, the user's
  # login passphrase is the only unlock method.
  security.pam.enableFscrypt = true;
}
