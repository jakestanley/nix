# kestrel

Work PC. Runs on the same physical hardware as shrike, sharing `/boot` as a separate boot entry.

## Deploying

See the root README for deployment order. Always deploy kestrel before shrike so shrike remains the default boot entry.

## Post-deploy steps

### Home directory encryption (LUKS)

`/home/work` is on a LUKS-encrypted partition. The passphrase is prompted at boot by the initrd. No manual setup is required after first deploy.

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


## Switching to shrike

Run `switch-to-gaming` from a terminal. This sets shrike as the one-shot boot entry and reboots.
