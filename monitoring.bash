#!/bin/bash

PROCESS_NAME="test"
LOG_FILE="/var/log/monitoring.log"
URL="https://test.com/monitoring/test/api"
USERNAME="simple-user"
FORCE=true

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
    -p --process-name  Process for control
    -l --log-file      Path to the log file
    -r --url           Api address
    -u --username      Run as user
    -f --force         Skip root check

Supports distributions: 
    Debian: 
    Redhat: 
    Arch: 
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
    if [ "$FORCE" = true ] && [ "$EUID" -ne 0 ]; then
        pretty_print "Please run as root"
        exit
    fi
}

arg_roasting(){
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -p|--process-name) PROCESS_NAME="$2"; shift ;;
            -l|--log-file) LOG_FILE=$2 ;;
            -r|--url) URL=$2 ;;
            -u|--username) USERNAME=$2 ;;
            -f|--force) FORCE=false ;;
            *) pretty_print "Unknown parameter passed: $1"; exit 1 ;;
        esac
        shift
    done
    pretty_print "Process for control  : $PROCESS_NAME"
    pretty_print "Path to the log file : $LOG_FILE"
    pretty_print "Api address          : $URL"
    pretty_print "Run as user          : $URL"
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
    if [ "$USERNAME" = "root" ]; then
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

print_help
root_check
arg_roasting
install_pgrep
process_checker
