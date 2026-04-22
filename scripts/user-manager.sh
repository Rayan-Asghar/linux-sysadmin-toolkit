#!/bin/bash
#======================================
#Script Name: user-manager.sh
#Description: Manages Users on a system create delete or listing users
#              Logs results with timestamps. Alerts to terminal
#              when action performed.
#Author: Rayan Asghar
#Date: April 22, 2026
#Version: 0.0.1
#Usage: ./user-manager.sh create <username>
#        ./user-manager.sh delete <username>
#        ./user-manager.sh list
#======================================
#Variables

#Location of log file
LOG_DIR="/var/log/sysadmin-toolkit"

#List log file
LOG_FILE="user-manager.log"

#Full path to the log file
LOG_PATH="$LOG_DIR/$LOG_FILE"

#Log rotating
MAX_LOG_BYTES=1048576 

#============================================

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

#======================================
#SETUP
setup(){
    if [ ! -d "$LOG_DIR" ] ;then
        mkdir -p "$LOG_DIR"
        chmod 755 "$LOG_DIR"
    fi
    #Rotete Log If it has grown too large
    if [ -f "$LOG_PATH" ] &&  [ "$(stat -c%s "$LOG_PATH")" -ge "$MAX_LOG_BYTES" ]; then
        mv "$LOG_PATH" "$LOG_PATH.old"
        log_info "Log rotated — previous log saved as user-manager.log.old"
    fi
    if [ "$EUID" -ne 0 ]; then
        echo "ERROR: This script must be run as root. Use: sudo ./user-manager.sh"
        exit 1
    fi
}

setup


#==============================================
#USER Functions

create_user(){
    local USERNAME="$1"
    #Check if the username was provided
    if [ -z "$USERNAME" ]; then
        echo "ERROR: No username provided"
        exit 1
    fi

    #Check user does not already exist
    if id "$USERNAME" &>/dev/null ; then
        log_warning "User $USERNAME already exists"
        echo "ERROR: User $USERNAME already exists"
        exit 1
    fi

    # Prompt for password silently
    read -s -p "Enter Pasword for $USERNAME: " PASSWORD
    echo

    #Create USER with home dir and bash shell
    useradd -m -s /bin/bash "$USERNAME"

    #Set the password
    echo "$USERNAME:$PASSWORD" | chpasswd

    #Log and confirm 
    log_ok "User $USERNAME was created by $USER"
    echo " User $USERNAME was created"
}

#Delete User 
delete_user(){
    local USERNAME="$1"
    #Check if the username was provided 
    if [ -z "$USERNAME" ] ;then
        echo "ERROR: No username provided"
        exit 1
    fi
    if ! id "$USERNAME" &>/dev/null ; then
        log_warning "The User $USERNAME does not exist"
        echo "ERROR: User $USERNAME does not exist"
        exit 1
    fi
    read -p "Are you sure you want to delete $USERNAME? (yes/no): " CONFIRM
    if [  "$CONFIRM" != "yes"  ] ;then
        echo "Aborted."
        exit 0
    fi
        userdel -r "$USERNAME"

    log_ok "Success:User $USERNAME deleted by $USER"
    echo "Success: The User $USERNAME deleted"
}

#List Users
list_users(){
    #List all the real users on the server
    echo "==========================================="
    echo "REAL Users On THis System"
    echo

    awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd

    log_info "User List viewed by $USER"
}

#===================================================
#MAIN

case "$1" in
    create)
        create_user "$2"
        ;;
    delete)
        delete_user "$2"
        ;;
    list)
        list_users
        ;;
    *)
        echo "ERROR: Unknown action '$1'"
        echo "Usage: ./user-manager.sh create|delete|list <username>"
        exit 1
        ;;
esac