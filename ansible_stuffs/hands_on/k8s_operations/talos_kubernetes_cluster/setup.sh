#!/bin/bash

set -e

SSH_KEY="./ssh/id_rsa"
INVENTORY_FILE="inventory/hosts.ini"
KNOWN_HOSTS_FILE="$HOME/.ssh/known_hosts"

echo "📁 Creating SSH directory if not exists ..."
mkdir -p ./ssh
chmod 700 ./ssh

# Generate ED25519 SSH key if not present
if [ ! -f "$SSH_KEY" ]; then
    echo "🔐 Generating ED25519 SSH key ..."
    ssh-keygen -t ed25519 -a 100 -q -N "" -f "$SSH_KEY"
else
    echo "✅ SSH key already exists."
f

# Parse inventory for remote hosts
echo "📦 Parsing Ansible inventory for remote hosts ..."
REMOTE_HOSTS=$(grep -E '^server[0-9]+|^agent[0-9]+' "$INVENTORY_FILE" | awk '{print $2}' | cut -d'=' -f2)

# Add hosts to known_hosts
for HOST in $REMOTE_HOSTS; do
    echo "🔑 Adding $HOST to known_hosts ..."
    ssh-keyscan -H "$HOST" >> "$KNOWN_HOSTS_FILE" 2>/dev/null
done

# Run the Ansible playbook
echo "🚀 Running Ansible Playbook ..."
ansible-playbook k8s.yaml -i "$INVENTORY_FILE" --key-file "$SSH_KEY"
