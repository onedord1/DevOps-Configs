#!/bin/bash


# Set script to exit on any error
set -e

# Define variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$HOME/ansible-venv"
LOGS_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOGS_DIR/ansible_migration_$(date +%Y%m%d_%H%M%S).log"

# Create logs directory if it doesn't exist
mkdir -p "$LOGS_DIR"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Start logging
log "Starting Ansible database migration script"

#Install Python3 if not already installed
log "Checking if Python3 is installed..."
if ! command -v python3 &> /dev/null; then
    log "Python3 is not installed. Installing..."
    sudo apt update
    sudo apt install -y python3
fi

# Install Python virtual environment
log "Installing Python virtual environment..."
sudo apt install -y python3-venv

# Create virtual environment
log "Creating Python virtual environment..."
python3 -m venv "$VENV_DIR"

# Activate virtual environment
log "Activating virtual environment..."
source "$VENV_DIR/bin/activate"

# Upgrade pip
log "Upgrading pip..."
pip install --upgrade pip

# Install required packages
log "Installing required Python packages..."
pip install ansible kubernetes psycopg2-binary jmespath

# Run Ansible playbook
log "Running Ansible playbook..."
ansible-playbook -vvv -i "$SCRIPT_DIR/inventories/var.ini" "$SCRIPT_DIR/playbooks/main.yaml" 2>&1 | tee -a "$LOG_FILE"

# Capture the exit code
ANSIBLE_EXIT_CODE=${PIPESTATUS[0]}

# Log completion status
if [ $ANSIBLE_EXIT_CODE -eq 0 ]; then
    log "Ansible playbook completed successfully"
else
    log "ERROR: Ansible playbook failed with exit code $ANSIBLE_EXIT_CODE"
fi

# Deactivate virtual environment
log "Deactivating virtual environment..."

deactivate

# Log script completion
log "Script completed with exit code $ANSIBLE_EXIT_CODE"
log "Details Log file saved to: $LOG_FILE"

# Exit with the same code as ansible-playbook
exit $ANSIBLE_EXIT_CODE