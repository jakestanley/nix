#!/usr/bin/env bash
set -euo pipefail

cleanup() {
    echo "Starting docker and plex..."
    sudo systemctl start docker
    sudo systemctl start plexmediaserver
}

trap cleanup EXIT

echo "Stopping docker and plex"

sudo systemctl stop docker
sudo systemctl stop plexmediaserver

echo "Stopped docker and plex. Beginning backup"

BACKUP_TARGET_HOME=/home/jake
BACKUP_DEST="$BACKUP_TARGET_HOME/Dropbox/backups/adler"
TIMESTAMP=$(date +%F_%H-%M)
BACKUP_FILE="$BACKUP_DEST/adler-$TIMESTAMP.tar.gz"

mkdir -p "$BACKUP_DEST"

sudo tar -czf "$BACKUP_FILE" \
    --warning=no-file-ignored \
    --exclude="$BACKUP_TARGET_HOME/.cache" \
    --exclude="$BACKUP_TARGET_HOME/.local/share/Trash" \
    --exclude="$BACKUP_TARGET_HOME/.local/pipx" \
    --exclude="$BACKUP_TARGET_HOME/.npm" \
    --exclude="$BACKUP_TARGET_HOME/.nvm" \
    --exclude="$BACKUP_TARGET_HOME/.codex" \
    --exclude="$BACKUP_TARGET_HOME/.dropbox" \
    --exclude="$BACKUP_TARGET_HOME/.dropbox-dist" \
    --exclude="$BACKUP_TARGET_HOME/.vscode-server" \
    --exclude="$BACKUP_TARGET_HOME/.cargo" \
    --exclude="$BACKUP_TARGET_HOME/node_modules" \
    --exclude="$BACKUP_TARGET_HOME/Downloads" \
    --exclude="$BACKUP_TARGET_HOME/Dropbox" \
    --exclude="$BACKUP_TARGET_HOME/.local/share/Steam" \
    --exclude="$BACKUP_TARGET_HOME/**/__pycache__" \
    --exclude="$BACKUP_TARGET_HOME/**/*.pyc" \
    --exclude="*/.git" \
    --exclude="$BACKUP_TARGET_HOME/Music/Playlists" \
    --exclude="*/.venv" \
    --exclude="*/venv" \
    --exclude="*/ipc-socket" \
    $BACKUP_TARGET_HOME \
    /etc/openvpn \
    /etc/homelab/certs \
    /var/lib/plexmediaserver

# keep last 7 backups
# shellcheck disable=SC2012
ls -t "$BACKUP_DEST"/adler-*.tar.gz | tail -n +8 | xargs -r rm

sudo chown jake:jake "$BACKUP_FILE"
echo "Backup complete: $BACKUP_FILE"
