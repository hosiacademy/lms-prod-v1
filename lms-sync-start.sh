#!/bin/bash

# Start the LMS sync service

SCRIPT_DIR="/home/takawira"
PID_FILE="$SCRIPT_DIR/.lms-sync.pid"
LOG_FILE="$SCRIPT_DIR/lms-sync.log"

# Check if already running
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "LMS sync is already running (PID: $PID)"
        echo "Check logs at: $LOG_FILE"
        exit 0
    else
        # Stale PID file, remove it
        rm "$PID_FILE"
    fi
fi

# Start the sync script in background
echo "Starting LMS bidirectional sync..."
nohup "$SCRIPT_DIR/lms-sync.sh" > "$LOG_FILE" 2>&1 &
echo $! > "$PID_FILE"

echo "LMS sync started (PID: $(cat $PID_FILE))"
echo "Logs: $LOG_FILE"
echo "To stop: run lms-sync-stop.sh"
