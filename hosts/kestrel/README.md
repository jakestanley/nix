# kestrel

Work PC. Runs on the same physical hardware as shrike, sharing `/boot` as a separate boot entry.

## Deploying

See the root README for deployment order. Always deploy kestrel before shrike so shrike remains the default boot entry.

## Post-deploy steps

### Home directory encryption (fscrypt)

fscrypt is enabled via `encryption.nix`. After first boot into kestrel:

1. Enable the encrypt feature on the root filesystem (one-time, permanent):

```sh
sudo tune2fs -O encrypt /dev/nvme0n1p3
```

2. Initialise fscrypt and encrypt the home directory. Clear any existing files first (zsh creates a few on first login), then encrypt using the login passphrase when prompted:

```sh
unset HISTFILE
rm -f ~/.lesshst ~/.zcompdump ~/.zsh_history
sudo fscrypt setup
sudo fscrypt encrypt /home/work --user=jake
```

The user's login passphrase is the unlock key. TPM2 binding is deferred to a later phase.

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
