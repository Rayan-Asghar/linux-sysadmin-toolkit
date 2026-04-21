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
MAX_LOG_BYTES=1048576 


#=========================================
#Dependencies check 
# Fail loudly if required tools are
# missing rather than failing silently
# mid-execution.
#--------------------------------------
check_dependencies() {
    for CMD in df awk cut grep stat mkdir; do
        if ! command -v "$CMD" &>/dev/null; then
            echo "ERROR: Required command '$CMD' not found. Aborting."
            exit 1
        fi
    done
}

#==========================================
# Logging Functions
# Centralised logging ensures consistent
# format across every log entry.
# Timestamp is captured at write time —
# not once at script startup.
#==========================================

log_ok() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] OK:      $1" >> "$LOG_PATH"
}

log_warning() {
    local MESSAGE="$1"
    # tee writes to log AND prints to terminal in one command
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $MESSAGE" | tee -a "$LOG_PATH"
}

log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO:    $1" >> "$LOG_PATH"
}

#=========================================
#Setup

setup() {
    # Create log directory with correct permissions
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR"
        chmod 755 "$LOG_DIR"
    fi

    # Rotate log if it has grown too large
    if [ -f "$LOG_PATH" ] && [ "$(stat -c%s "$LOG_PATH")" -ge "$MAX_LOG_BYTES" ]; then
        mv "$LOG_PATH" "${LOG_PATH}.old"
        log_info "Log rotated — previous log saved as disk-monitor.log.old"
    fi
}

#======================================================
#Disk Check
# Reads all real mounted partitions.
# Logs OK entries to file only.
# Logs WARNING entries to file AND terminal.
# Returns 1 if any partition breached
# the threshold, 0 if all clear.
#======================================

check_disk_usage() {
    local ALERT=false

    log_info "Disk check started"

    while read -r LINE; do
        # Extract usage percentage (strip the % sign) and partition name
        USAGE=$(echo "$LINE" | awk '{print $5}' | cut -d'%' -f1)
        PARTITION=$(echo "$LINE" | awk '{print $6}')

        if [ "$USAGE" -ge "$THRESHOLD" ]; then
            log_warning "$PARTITION is at ${USAGE}% - above threshold of ${THRESHOLD}%"
            ALERT=true
        else
            log_ok "$PARTITION is at ${USAGE}%"
        fi

    done < <(df -h | grep -vE '^Filesystem|tmpfs|udev|efivarfs')

    log_info "Disk check complete"

    # Return status so main() can set the exit code
    if [ "$ALERT" = true ]; then
        return 1
    fi
    return 0
}


#===========================================
# Main
# Orchestrates execution in order.
# All logic lives in functions above.
# This reads like a table of contents
#=============================================
main() {
    check_dependencies
    setup
    check_disk_usage
    local EXIT_CODE=$?

    # Summary line always prints to terminal
    echo "Disk check complete. Full results: $LOG_PATH"

    exit $EXIT_CODE
}

main "$@"