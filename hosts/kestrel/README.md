# kestrel

Work PC. Runs on the same physical hardware as shrike, sharing `/boot` as a separate boot entry.

## Deploying

See the root README for deployment order. Always deploy kestrel before shrike so shrike remains the default boot entry.

## Post-deploy steps

### First boot after reinstall

```sh
sudo mkdir -p /nix/var/nix/profiles/per-user/jake
sudo chown jake:jake /nix/var/nix/profiles/per-user/jake
sudo chown -R jake:jake /home/work
home-manager switch --flake .#jake@kestrel
```

### Home directory encryption (LUKS)

`/home/work` is on a LUKS-encrypted partition (UUID `817ea6d0-01f1-4e25-907d-bba18fd4988d`). The passphrase is prompted at boot by the initrd.

A TPM2 keyslot can be enrolled to unlock automatically at boot without a passphrase prompt (tied to PCRs 0+7 — firmware integrity and Secure Boot state). To enrol:

```sh
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 \
  /dev/disk/by-uuid/817ea6d0-01f1-4e25-907d-bba18fd4988d
```

The passphrase keyslot is preserved as a fallback. Re-enrolment is required after a UEFI firmware update (PCR 0 changes) or Secure Boot key rotation (PCR 7 changes).

To reformat or re-encrypt (e.g. after reinstall), boot into shrike and run:

```sh
cryptsetup luksFormat /dev/nvme?n1p?   # find the right device with lsblk first
cryptsetup open /dev/nvme?n1p? work
mkfs.ext4 -L nixos-kestrel /dev/mapper/work
cryptsetup luksUUID /dev/nvme?n1p?     # update hardware-configuration.nix with new UUID
cryptsetup close work
```

### Hibernate resume offset

The swap file at `/var/swap/hibernate` is created on first deploy. After deploying, SSH in and run:

```sh
sudo filefrag -v /var/swap/hibernate | awk 'NR==4{print $4}' | tr -d '.'
```

Set the output value in `hibernate.nix`:

```nix
boot.kernelParams = [ "resume_offset=<value>" ];
```

Then redeploy.


## Manual post-deploy installs

Some packages are not in nixpkgs and must be installed manually:

```sh
nix-env -if https://github.com/vlaci/openconnect-sso/archive/master.tar.gz
```

## Switching to shrike

Run `switch-to-gaming` from a terminal. This sets shrike as the one-shot boot entry and reboots.
