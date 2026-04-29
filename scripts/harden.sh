#!/bin/bash
#======================================
#Script Name: harden.sh
#Description: Audits a Linux Server's security and
#             produces a clear pass/fail report 
#             It only checks doesnot fix.
#Author: Rayan Asghar
#Date: April 26, 2026
#Version: 0.0.1
#Usage: sudo ./harden.sh
#======================================
#Variables

#Location of log file
LOG_DIR="/var/log/sysadmin-toolkit"

#List log file
LOG_FILE="harden.log"

#Full path to the log file
LOG_PATH="$LOG_DIR/$LOG_FILE"

#Counters for pass/fail checks
PASSED=0
FAILED=0

log_ok() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] OK:      $1" >> "$LOG_PATH"
}

log_warning() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1" | tee -a "$LOG_PATH"
}

log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO:    $1" >> "$LOG_PATH"
}


setup(){
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR"
        chmod 755 "$LOG_DIR"
    fi

    if [ "$(id -u)" -ne 0 ]; then
        echo "Please run as root"
        exit 1
    fi
}

run_check(){
    local DESCRIPTION="$1"
    local COMMAND="$2"

    if eval "$COMMAND" &>/dev/null; then
        echo "[PASS] $DESCRIPTION"
        log_ok "PASS: $DESCRIPTION"
        PASSED=$((PASSED+1))
    else
        echo "[FAIL] $DESCRIPTION"
        log_warning "FAIL: $DESCRIPTION"
        FAILED=$((FAILED+1))
    fi   
}

#==============================================
#Security Checks

run_checks(){
    log_info "Hardening Audit Started"
    echo "=========================================="
    echo "Linux Security Hardening Audit"
    echo "=========================================="
    echo
    run_check "SSH root login is diabled" \
        "grep -qE '^PermitRootLogin no' /etc/ssh/sshd_config"

    run_check "SSH password authentication is disabled" \
        "grep -qE '^PasswordAuthentication no' /etc/ssh/sshd_config"

    run_check "UFW firewall is active" \
        "ufw status | grep -q 'Status: active'"
    run_check "fail2ban is installed and running" \
        "systemctl is-active fail2ban"

    run_check "No accounts with empty passwords" \
        "! awk -F: '(\$2==\"\")' /etc/shadow | grep -q ."

    run_check "Root account is locked from direct login" \
        "passwd -S root | grep -q ' L '"

    echo
}   

#======================================
# SUMMARY
#======================================
summary(){
    echo "=========================================="
    echo "  AUDIT COMPLETE"
    echo "=========================================="
    echo "Total Test's Passes = $PASSED"
    # print total failed
    echo "Total test Failed = $FAILED"
    # print total checks
    echo "Total Checks ran = $((PASSED + FAILED))"

    # if FAILED is greater than 0 exit 1
    if [ "$FAILED" -gt 0 ]; then
        exit 1
    else 
        exit 0
    fi
    # otherwise exit 0
}

main(){
    setup
    run_checks
    summary
    
}

main