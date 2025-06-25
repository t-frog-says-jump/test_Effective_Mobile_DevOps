#!/bin/bash

PROCESS_NAME="test"
LOG_FILE="/var/log/monitoring.log"
URL="https://test.com/monitoring/test/api"
USERNAME="root"

FORCE=false

HELP="\
Simple bash script to monitoring some process.
Expects that the su, useradd, id, echo, printf
commands are available in the system.

By default use: 
    process-name: test
    log-file: /var/log/monitoring.log
    url: https://test.com/monitoring/test/api
    username: simple-user

Args:   
    -p --process-name    Process for control
    -l --log-file        Path to the log file
    -r --url             Api address
    -u --username        Run as user
    -f --force           Skip root check

Tested in docker for distributions: 
    Debian: debian:trixie-slim
    Redhat: redhat/ubi9:9.6
    Arch: archlinux:base-20250622.0.370030
    
Tested on self-hosted:
    Ubuntu: 24.04.1
"

pretty_print() {
    local message="$1"
    local border_char="${2:-*}"
    local border_length=${#message}
    
    printf "%${border_length}s\n" | tr ' ' "$border_char"
    echo "$message"
    printf "%${border_length}s\n" | tr ' ' "$border_char"
}

print_help(){
    echo "$HELP"
}

root_check() {
    if [[ $FORCE == false ]] && [ "$EUID" -ne 0 ]; then
        pretty_print "Please run as root"
        exit
    fi
}

arg_roasting(){
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -p|--process-name) PROCESS_NAME="$2"; shift ;;
            -l|--log-file) LOG_FILE="$2"; shift ;;
            -r|--url) URL="$2"; shift ;;
            -u|--username) USERNAME="$2"; shift ;;
            -f|--force) FORCE=true ;;
            *) pretty_print "Unknown parameter passed: $1"; exit 1 ;;
        esac
        shift
    done
    echo "Process for control     $PROCESS_NAME"
    echo "Path to the log file    $LOG_FILE"
    echo "Api address             $URL"
    echo "Run as user             $USERNAME"
    echo "Run with force          $FORCE"
    echo
}

install_pgrep() {
    if [ -f /etc/debian_version ]; then
        sudo apt-get update
        sudo apt-get install -y procps
    elif [ -f /etc/redhat-release ]; then
        sudo yum install -y pgrep
    elif [ -f /etc/arch-release ]; then
        sudo pacman -Syu --noconfirm procps-ng
    else
        pretty_print "Unsupported distribution"
        exit 1
    fi
}

create_user() {
    if id "$USERNAME" &>/dev/null; then
        pretty_print "User $USERNAME already exists."
    else
        useradd -m "$USERNAME"
        pretty_print "User $USERNAME created."
    fi
}

switch_privelege(){
    if [ "$USERNAME" != "root" ]; then
        create_user
        su - "$USERNAME"
    fi
}

process_checker() {
    if pgrep -x "$PROCESS_NAME" > /dev/null; then
        if ! curl --silent --fail "$URL" > /dev/null; then
            echo "$(date): Monitoring server is down." >> "$LOG_FILE"
        else
            echo "$(date): Process '$PROCESS_NAME' is running." >> "$LOG_FILE"
        fi
    else
        echo "$(date): Process '$PROCESS_NAME' is not running." >> "$LOG_FILE"
    fi
}

print_help        &&
arg_roasting $*   &&
root_check        &&
install_pgrep     &&
switch_privelege  &&
process_checker
