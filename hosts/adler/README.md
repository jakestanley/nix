# adler

## Manual steps

### Tailscale

After first deploy that enables Tailscale, authenticate the node into your tailnet:

```sh
sudo tailscale up
```

Verify with `tailscale status` and `systemctl status tailscaled docker`.

### TLS certificates

Copy the wildcard cert and CA from the Ubuntu box before first activation:

```sh
# or from wherever they are
scp -r user@ubuntu:/etc/homelab/certs /tmp/certs
sudo mkdir -p /etc/homelab/certs
sudo cp -r /tmp/certs/* /etc/homelab/certs/
sudo chmod 600 /etc/homelab/certs/live/wildcard_stanley_arpa/privkey.pem
```

Alternatively, generate certs using the scripts in [homelab-edge](https://github.com/jakestanley/homelab-edge).

If you generate new certs you'll need to re-add them to client trust stores.

Still having permissions issues? Try:

```sh
ls -la /etc/homelab/certs/live/wildcard_stanley_arpa/
sudo chmod 640 /etc/homelab/certs/live/wildcard_stanley_arpa/privkey.pem
sudo chown root:nginx /etc/homelab/certs/live/wildcard_stanley_arpa/privkey.pem
sudo systemctl restart nginx
```

### OpenVPN

The PKI files are managed outside of Nix. Copy them from the Ubuntu box before first activation:

```sh
sudo scp -r user@ubuntu:/etc/openvpn /etc/openvpn
```

Ensure correct permissions:

```sh
sudo chmod 600 /etc/openvpn/ca.key
sudo chmod 600 /etc/openvpn/server_YeWnWJLw5SiBcE91.key
sudo chmod 600 /etc/openvpn/tls-crypt.key
```

The client configs and CCD directory are included in the copy. The `ipp.txt` lease file will be created automatically by OpenVPN on first run if it does not exist.

### Plex Media Server

Stop Plex before copying to avoid in-use file issues:

```sh
sudo systemctl stop plexmediaserver
nohup sudo rsync -av --progress /var/lib/plexmediaserver/ /mnt/nixos-var-lib/plexmediaserver/ > /tmp/rsync-plex.log 2>&1 &
```

Ensure correct ownership after copy:

```sh
sudo chown -R plex:plex /mnt/nixos-var-lib/plexmediaserver
```

Note: media files are on ZFS volumes (`/var/media`, `/var/archive`) and do not need to be copied.

### Docker

Stop all containers before copying:

```sh
sudo docker stop $(sudo docker ps -q)
```

Clean up unused images, containers and volumes to reduce copy size:

```sh
sudo docker system prune -a --volumes
```

Copy Docker data to NixOS partition:

```sh
sudo systemctl stop docker
nohup sudo rsync -av --progress /var/lib/docker/ /mnt/nixos-var-lib/docker/ > /tmp/rsync-docker.log 2>&1 &
```

### Backup script

The script `./scripts/backup-adler.sh` needs to be run as root, add this using `sudo crontab -e`:

```
0 2 * * * /home/jake/git/github.com/jakestanley/nix/scripts/backup-adler.sh >> /var/log/backup-adler.log 2>&1
```
