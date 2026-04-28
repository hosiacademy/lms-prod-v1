#!/bin/bash

# Stop the LMS sync service

SCRIPT_DIR="/home/takawira"
PID_FILE="$SCRIPT_DIR/.lms-sync.pid"

if [ ! -f "$PID_FILE" ]; then
    echo "LMS sync is not running (no PID file found)"
    exit 0
fi

PID=$(cat "$PID_FILE")

if ps -p "$PID" > /dev/null 2>&1; then
    echo "Stopping LMS sync (PID: $PID)..."
    # Kill the main process and its children
    pkill -P "$PID"
    kill "$PID"
    rm "$PID_FILE"
    echo "LMS sync stopped"
else
    echo "LMS sync is not running (PID $PID not found)"
    rm "$PID_FILE"
fi
