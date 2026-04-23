#!/bin/bash
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

#Backup Source COmes from command line argument
SOURCE="$1"

#TImeStamp of backup taken
TIMESTAMP=$(date +'%Y-%m-%d-%H-%M-%S' )

#Backupfile name with timestamp 
BACKUP_FILE="backup-${TIMESTAMP}.tar.gz"

#Maxbackups to keep 
MAX_BACKUPS=5

#BackUp Location
BACKUP_DIR="/var/backups/sysadmin"


# Log file location
LOG_DIR="/var/log/sysadmin-toolkit"
LOG_FILE="backup.log"
LOG_PATH="$LOG_DIR/$LOG_FILE"



log_ok(){
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]OK:  $1">> "$LOG_PATH"
}

log_warning(){
    local MESSAGE="$1"
    # tee writes to log AND prints to terminal in one command
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Warning:$MESSAGE" | tee -a "$LOG_PATH"
}   

log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO:    $1" >> "$LOG_PATH"
}

#===========================================================
#SETUP

setup(){
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR"
        chmod 755 "$LOG_DIR"
    fi

    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        chmod 755 "$BACKUP_DIR"
    fi

    if [ ! -w "$BACKUP_DIR" ]; then
        echo "ERROR: BAckup Directory $BACKUP_DIR is not writable"
        exit 1
    fi

    if [ -z "$SOURCE" ]; then
        echo "ERROR: No Source provided"
        exit 1
    fi
    if [ ! -d "$SOURCE" ]; then
        echo "ERROR: Source Directory $SOURCE does not exist"
        exit 1
    fi

}

setup
#======================================
#BACKUP

echo "Backup In Progress"

tar -czf "$BACKUP_DIR/$BACKUP_FILE" "$SOURCE"

if [ $? -ne 0 ]; then
    log_warning "Backup of $SOURCE failed"
    echo "ERROR: Backup Failed"
    exit 1
fi

log_ok "Backup of $SOURCE created "

#List files sorted by time, skip the first 5 and return whatever's left. Delete the remaining content
ls -t "$BACKUP_DIR"/backup-*.tar.gz | tail -n +$((MAX_BACKUPS+1)) | xargs -r rm --
if [ $? -ne 0 ]; then
    log_warning "Log Retention failed "
    echo "Error: Log Retention failed"
    exit 1
fi

log_info "Retention Cleanup ran -- Keeping last $MAX_BACKUPS backups"
echo "SUCCESS: Backup Complete -- $BACKUP_DIR/$BACKUP_FILE"

exit 0
