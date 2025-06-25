PROCESS_NAME="test"
LOG_FILE="/var/log/monitoring.log"
URL="https://test.com/monitoring/test/api"

install_pgrep() {
    if [ -f /etc/debian_version ]; then
        sudo apt-get update
        sudo apt-get install -y procps
    elif [ -f /etc/redhat-release ]; then
        sudo yum install -y pgrep
    elif [ -f /etc/arch-release ]; then
        sudo pacman -Syu --noconfirm procps-ng
    elif [ -f /etc/SuSE-release ]; then
        sudo zypper install -y procps
    else
        echo "Unsupported distribution"
        exit 1
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

install_pgrep
process_checker
