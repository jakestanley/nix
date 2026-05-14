# kestrel

Work PC. Runs on the same physical hardware as shrike, sharing `/boot` as a separate boot entry.

## Deploying

See the root README for deployment order. Always deploy kestrel before shrike so shrike remains the default boot entry.

## Post-deploy steps

### Home directory encryption (fscrypt)

`/home/work` lives on a dedicated partition (`/dev/disk/by-label/nixos-kestrel`). Before first boot into kestrel, enable the ext4 encrypt feature on that partition while it is unmounted (e.g. from the live USB or from shrike):

```sh
sudo tune2fs -O encrypt /dev/disk/by-label/nixos-kestrel
```

This only needs to be done once. After first boot into kestrel, initialise fscrypt and encrypt the home directory. Clear any files zsh created on first login before encrypting:

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

### Home Manager

`home-manager-jake.service` runs at boot before fscrypt unlocks `/home/work` and will fail. Once the graphical session is running, sway's startup config restarts it automatically. For SSH-only access, restart it manually:

```sh
sudo systemctl restart home-manager-jake.service
```

## Switching to shrike

Run `switch-to-gaming` from a terminal. This sets shrike as the one-shot boot entry and reboots.
