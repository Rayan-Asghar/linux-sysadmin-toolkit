#!/bin/bash
set -e
set -o pipefail
#======================================
#Script Name: backup.sh
#Description: Creates a compressed timestamped backup of a specified
#             directory. Retains only the last 5 backups and removes
#             older ones automatically.
#Author: Rayan Asghar
#Date: April 23, 2026
#Version: 0.0.1
#Usage: ./backup.sh <source_directory>
#======================================
#Variables

#Backup Source Comes from command line argument
SOURCE="$1"

#TimeStamp of backup taken
TIMESTAMP=$(date +'%Y-%m-%d-%H-%M-%S' )

#Backupfile name with timestamp 
BACKUP_FILE="backup-${TIMESTAMP}.tar.gz"

#Maxbackups  
MAX_BACKUPS=5

#Back Up Location
BACKUP_DIR="/var/backups/sysadmin"


# Log file location
LOG_DIR="/var/log/sysadmin-toolkit"
LOG_FILE="backup.log"
LOG_PATH="$LOG_DIR/$LOG_FILE"

#Blocked Paths

BLOCKED_PATHS=("/" "/etc" "/root" "/proc" "/sys")

log_ok() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] OK:      $1" >> "$LOG_PATH"
}

log_warning() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1" | tee -a "$LOG_PATH"
}

log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO:    $1" >> "$LOG_PATH"
}

#============================================
#Check Dependencies

check_dependencies(){
    local DEPS=("tar" "ls" "xargs" "du" "realpath")
    for DEP in "${DEPS[@]}"; do
        if ! command -v "$DEP" &>/dev/null; then
            echo "ERROR: Required tool '$DEP' is not installed"
            exit 1
        fi
    done
    log_info "Dependency Check Passed"
}
#===========================================================
#SETUP

setup(){
    if [ -z "$SOURCE" ]; then
        echo "ERROR: No Source provided"
        exit 1
    fi

    SOURCE=$(realpath "$SOURCE" 2>/dev/null) || {
    echo "ERROR: Cannot resolve path: $SOURCE"
    exit 1
    }

    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR"
        chmod 755 "$LOG_DIR"
    fi

    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        chmod 700 "$BACKUP_DIR"
    fi

    if [ ! -w "$BACKUP_DIR" ]; then
        echo "ERROR: Backup Directory $BACKUP_DIR is not writable"
        exit 1
    fi

   
    if [ ! -d "$SOURCE" ]; then
        echo "ERROR: Source Directory $SOURCE does not exist"
        exit 1
    fi

    for BLOCKED in "${BLOCKED_PATHS[@]}"; do
        if [ "$SOURCE" = "$BLOCKED" ]; then
            echo "ERROR: Backing up $SOURCE is not permitted"
            exit 1
        fi
    done

}

#======================================
#BACKUP

run_backup(){

    echo "Backup In Progress"

    tar -czf "$BACKUP_DIR/$BACKUP_FILE" "$SOURCE" || {
        log_warning "Backup of $SOURCE failed"
        echo "ERROR: Backup Failed"
        exit 1
    }
    BACKUP_SIZE=$(du -sh "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)

    log_ok "Backup of $SOURCE created --Size: $BACKUP_SIZE --File: $BACKUP_FILE"
    echo "SUCCESS: Backup Complete -- $BACKUP_DIR/$BACKUP_FILE"

}

run_retention(){
     #List files sorted by time, skip the first 5 and return whatever's left. Delete the remaining content
    ls -t "$BACKUP_DIR"/backup-*.tar.gz | tail -n +$((MAX_BACKUPS+1)) | xargs -r rm -- || {
    
        log_warning "Log Retention failed "
        echo "Error: Log Retention failed"
        exit 1
    }
    
    
    log_info "Retention Cleanup ran -- Keeping last $MAX_BACKUPS backups"

}

#==================================================
#MAIN

main(){
    setup
    check_dependencies
    run_backup
    run_retention
    exit 0
}



main "$@"