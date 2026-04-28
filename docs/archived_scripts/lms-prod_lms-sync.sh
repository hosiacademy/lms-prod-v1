#!/bin/bash

# Bidirectional sync script for lms-monorepo
# Syncs between Windows (C:\Users\HosiTech\lms-monorepo) and WSL (/home/takawira/lms-monorepo)

WINDOWS_DIR="/mnt/c/Users/HosiTech/lms-monorepo/"
WSL_DIR="/home/takawira/lms-monorepo/"
LOG_FILE="/home/takawira/lms-sync.log"

# Exclusions to avoid syncing
EXCLUDE_OPTS=(
    --exclude='.git'
    --exclude='node_modules'
    --exclude='.venv'
    --exclude='venv'
    --exclude='__pycache__'
    --exclude='*.pyc'
    --exclude='.next'
    --exclude='dist'
    --exclude='build'
    --exclude='.DS_Store'
)

# Function to sync from Windows to WSL
sync_windows_to_wsl() {
    echo "[$(date)] Syncing Windows -> WSL" >> "$LOG_FILE"
    rsync -av --delete "${EXCLUDE_OPTS[@]}" "$WINDOWS_DIR" "$WSL_DIR" >> "$LOG_FILE" 2>&1
}

# Function to sync from WSL to Windows
sync_wsl_to_windows() {
    echo "[$(date)] Syncing WSL -> Windows" >> "$LOG_FILE"
    rsync -av --delete "${EXCLUDE_OPTS[@]}" "$WSL_DIR" "$WINDOWS_DIR" >> "$LOG_FILE" 2>&1
}

# Initial sync from Windows to WSL
echo "[$(date)] Starting initial sync" >> "$LOG_FILE"
sync_windows_to_wsl

# Start watching both directories
echo "[$(date)] Starting bidirectional file watchers" >> "$LOG_FILE"

# Poll Windows directory every 5 seconds and sync to WSL (inotify doesn't work on /mnt/c)
while true; do
    sleep 5
    # Check if Windows directory has newer files
    if [ -d "$WINDOWS_DIR" ]; then
        sync_windows_to_wsl
    fi
done &

# Watch WSL directory with inotify and sync to Windows
inotifywait -m -r -e modify,create,delete,move "$WSL_DIR" --exclude '(.git|node_modules|.venv|venv|__pycache__|.next|dist|build)' 2>/dev/null | while read -r directory events filename; do
    sleep 1  # Debounce rapid changes
    sync_wsl_to_windows
done &

# Keep script running
echo "[$(date)] Sync service started. Press Ctrl+C to stop." | tee -a "$LOG_FILE"
wait
