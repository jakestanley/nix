#!/usr/bin/env bash
set -euo pipefail

cleanup() {
    echo "Starting docker and plex..."
    sudo systemctl start docker.socket
    sudo systemctl start docker
    sudo systemctl start plexmediaserver
}

trap cleanup EXIT

echo "Stopping docker and plex"

sudo systemctl stop docker.socket
sudo systemctl stop docker
sudo systemctl stop plexmediaserver

echo "Stopped docker and plex. Beginning backup"

BACKUP_TARGET_HOME=/home/jake
BACKUP_DEST="$BACKUP_TARGET_HOME/Dropbox/backups/adler"
TIMESTAMP=$(date +%F_%H-%M)
BACKUP_FILE="$BACKUP_DEST/adler-$TIMESTAMP.tar.gz"

mkdir -p "$BACKUP_DEST"

tar_exit=0
sudo tar -czf "$BACKUP_FILE" \
    --warning=no-file-ignored \
    --exclude="$BACKUP_TARGET_HOME/tmp" \
    --exclude="$BACKUP_TARGET_HOME/.local/share/claude" \
    --exclude="$BACKUP_TARGET_HOME/.zed_server" \
    --exclude="$BACKUP_TARGET_HOME/.cache" \
    --exclude="$BACKUP_TARGET_HOME/.local/share/Trash" \
    --exclude="$BACKUP_TARGET_HOME/.local/lib" \
    --exclude="$BACKUP_TARGET_HOME/.local/pipx" \
    --exclude="$BACKUP_TARGET_HOME/.npm" \
    --exclude="$BACKUP_TARGET_HOME/.nvm" \
    --exclude="$BACKUP_TARGET_HOME/.codex" \
    --exclude="$BACKUP_TARGET_HOME/.dropbox" \
    --exclude="$BACKUP_TARGET_HOME/.dropbox-dist" \
    --exclude="$BACKUP_TARGET_HOME/.vscode-server" \
    --exclude="$BACKUP_TARGET_HOME/.cargo" \
    --exclude="*/node_modules" \
    --exclude="*.mp4" \
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
    /etc/wireguard \
    /etc/homelab/certs \
    /var/lib/plexmediaserver || tar_exit=$?

# exit code 1 = files changed during archive (warning); 2+ = fatal
if [ "$tar_exit" -gt 1 ]; then
    echo "tar failed with exit code $tar_exit"
    exit "$tar_exit"
fi

# Tiered retention: daily for 7d, weekly for 8w, monthly for 6m
prune_backups() {
    local dir="$1"
    declare -A keep seen_day seen_week seen_month
    local today
    today=$(date +%s)

    while IFS= read -r file; do
        local name
        name=$(basename "$file")
        local date_str="${name:6:10}"  # adler-YYYY-MM-DD_…
        local file_ts
        file_ts=$(date -d "$date_str" +%s 2>/dev/null) || continue
        local age=$(( today - file_ts ))
        local week_key
        week_key=$(date -d "$date_str" +%G-%V)
        local month_key="${date_str:0:7}"

        if   (( age <=   7 * 86400 )) && [[ -z ${seen_day[$date_str]+x}    ]]; then
            seen_day[$date_str]=1;  keep[$file]=1
        elif (( age <=  56 * 86400 )) && [[ -z ${seen_week[$week_key]+x}   ]]; then
            seen_week[$week_key]=1; keep[$file]=1
        elif (( age <= 180 * 86400 )) && [[ -z ${seen_month[$month_key]+x} ]]; then
            seen_month[$month_key]=1; keep[$file]=1
        fi
    done < <(ls -t "$dir"/adler-*.tar.gz 2>/dev/null)

    while IFS= read -r file; do
        if [[ -z ${keep[$file]+x} ]]; then
            echo "Pruning: $file"
            rm "$file"
        fi
    done < <(ls "$dir"/adler-*.tar.gz 2>/dev/null)
}

prune_backups "$BACKUP_DEST"

sudo chown jake:jake "$BACKUP_FILE"
echo "Backup complete: $BACKUP_FILE"
