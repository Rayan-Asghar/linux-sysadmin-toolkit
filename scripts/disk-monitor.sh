#!/bin/bash
#======================================
#Script Name: disk-monitor.sh
#Description: Monitors disk usage on all mounted partitions.
#              Logs results with timestamps. Alerts to terminal
#              when usage exceeds the defined threshold.
#Author: Rayan Asghar
#Date: April 19, 2026
#Version: 0.0.1
#Usage: ./disk-monitor.sh
#======================================

#Location of log file
LOG_DIR="$HOME/logs"

#List log file
LOG_FILE="disk-monitor.log"

#Full path to the log file
LOG_PATH="$LOG_DIR/$LOG_FILE"

#Threshold Value
THRESHOLD=80


#=========================================
#Setup

mkdir -p "$LOG_DIR"

# Capture current timestamp for log entries
DATE=$(date '+%Y-%m-%d %H:%M:%S' )

#To Track If any partition breached the threshold
ALERT_FLAG="/tmp/disk-alert-flag"
rm -f "$ALERT_FLAG"

#======================================================
#Disk Check
while read -r LINE; do 
    USAGE=$(echo "$LINE" | awk '{print $5}' |cut -d'%' -f1)
    PARTITION=$(echo "$LINE" | awk '{print $6}')
    if [ "$USAGE" -ge "$THRESHOLD" ]; then
        echo "[$DATE] WARNING:$PARTITION is at ${USAGE}% - ABOVE THRESHOLD" >>"$LOG_PATH"
        echo "WARNING:$PARTITION is at ${USAGE}% -ABOVE THRESHOLD"
        touch "$ALERT_FLAG"
    else
        echo "[$DATE] OK: $PARTITION is at ${USAGE}%">> "$LOG_PATH"
    fi

done < <(df -h | grep -vE '^Filesystem|tmpfs|udev|efivarfs')

if [ -f "$ALERT_FLAG" ]; then
    rm -f "$ALERT_FLAG"
    exit 1
fi

exit 0
