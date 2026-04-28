#!/bin/bash

# Check status of LMS sync service

SCRIPT_DIR="/home/takawira"
PID_FILE="$SCRIPT_DIR/.lms-sync.pid"
LOG_FILE="$SCRIPT_DIR/lms-sync.log"

if [ ! -f "$PID_FILE" ]; then
    echo "Status: Not running"
    exit 0
fi

PID=$(cat "$PID_FILE")

if ps -p "$PID" > /dev/null 2>&1; then
    echo "Status: Running (PID: $PID)"
    echo "Log file: $LOG_FILE"
    echo ""
    echo "Recent log entries:"
    tail -n 10 "$LOG_FILE"
else
    echo "Status: Not running (stale PID file)"
    rm "$PID_FILE"
fi
