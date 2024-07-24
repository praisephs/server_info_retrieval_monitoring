#!/bin/bash

LOG_DIR="/home/praisephs/server_monitoring/devopsfetch_logs"
LOG_FILE="$LOG_DIR/devopsfetch.log"
MAX_SIZE=10485760  # 10 MB in bytes

# Check if the log file size exceeds the maximum size
if [ -f "$LOG_FILE" ]; then
    LOG_SIZE=$(stat -c%s "$LOG_FILE")

    if [ "$LOG_SIZE" -ge "$MAX_SIZE" ]; then
        TIMESTAMP=$(date +"%Y%m%d%H%M%S")
        mv "$LOG_FILE" "$LOG_DIR/devopsfetch_$TIMESTAMP.log"
        touch "$LOG_FILE"
    fi
fi
