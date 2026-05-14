{ ... }:

{
  # /home/work is on a LUKS-encrypted partition (UUID 817ea6d0-01f1-4e25-907d-bba18fd4988d).
  # The passphrase is prompted at boot by the initrd.
  # The decrypted device is mapped to /dev/mapper/work and mounted at /home/work.
  #
  # To reformat or re-encrypt, boot into shrike and run cryptsetup against the raw device.
}
