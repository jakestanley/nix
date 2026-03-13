#!/usr/bin/env bash
set -euo pipefail

BACKUP_DEST="$HOME/Dropbox/backups/adler"
TIMESTAMP=$(date +%Y%m%d)
BACKUP_FILE="$BACKUP_DEST/adler-$TIMESTAMP.tar.gz"

mkdir -p "$BACKUP_DEST"

tar -czf "$BACKUP_FILE" \
    --exclude="$HOME/.cache" \
    --exclude="$HOME/.local/share/Trash" \
    --exclude="$HOME/.local/pipx" \
    --exclude="$HOME/.npm" \
    --exclude="$HOME/.nvm" \
    --exclude="$HOME/.codex" \
    --exclude="$HOME/.dropbox" \
    --exclude="$HOME/.dropbox-dist" \
    --exclude="$HOME/.vscode-server" \
    --exclude="$HOME/.cargo" \
    --exclude="$HOME/node_modules" \
    --exclude="$HOME/Downloads" \
    --exclude="$HOME/Dropbox" \
    --exclude="$HOME/.local/share/Steam" \
    --exclude="$HOME/**/__pycache__" \
    --exclude="$HOME/**/*.pyc" \
    --exclude="*/.git" \
    --exclude="$HOME/Music/Playlists" \
    --exclude="*/.venv" \
    --exclude="*/venv" \
    /home/jake \
    /etc/openvpn \
    /etc/homelab/certs \
    /var/lib/plexmediaserver

# keep last 7 backups
# ls -t "$BACKUP_DEST"/adler-*.tar.gz | tail -n +8 | xargs -r rm

echo "Backup complete: $BACKUP_FILE"