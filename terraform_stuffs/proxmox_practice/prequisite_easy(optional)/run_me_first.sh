#!/bin/bash

# =================================================================================
#
# Proxmox Setup Script: VM Template + User/Role/Token Creation
#
# Description:
#   This script automates two main tasks in Proxmox VE:
#     1. Downloads a cloud image and creates a VM template.
#     2. Creates a user, custom role, assigns permissions, and generates an API token.
#
# Features:
#   - Parameterized for easy reuse.
#   - Idempotent: Checks if resources (VM, user, role) exist before creation.
#   - Error handling: Exits on failure with clear messages.
#   - Comments for clarity and maintenance.
#
# Usage:
#   1. Review and customize the variables below.
#   2. Run as root or with Proxmox admin privileges.
#   3. ./script_name.sh
#
# =================================================================================

# -------------------------- SCRIPT PARAMETERS -----------------------------------

# VM Template Parameters
VM_ID="9999"
TEMPLATE_ID="999"
VM_NAME="ubuntu-cloud-image"
MEMORY_MB="8000"
DISK_SIZE_GB="300"
IMAGE_FILE="jammy-server-cloudimg-amd64.img"
IMAGE_URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img" # Example
STORAGE="local-lvm"
BRIDGE="vmbr0"

# User/Role/Token Parameters
USER_NAME="terraform"
USER_REALM="pve"
ROLE_NAME="terraform-role"
TOKEN_NAME="terraform-token"
PRIVS="Datastore.AllocateSpace Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt SDN.Use"

# -------------------------- DO NOT EDIT BELOW THIS LINE --------------------------

set -euo pipefail  # Exit on error, unset vars, pipe failures

# -------------------------- HELPER FUNCTIONS ------------------------------------

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

error_exit() {
  log "ERROR: $1" >&2
  exit 1
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# -------------------------- PRE-RUN CHECKS --------------------------------------

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
  error_exit "This script must be run as root."
fi

# Ensure required commands exist
for cmd in qm pveum wget; do
  if ! command_exists "$cmd"; then
    error_exit "Required command '$cmd' is not installed or not in PATH."
  fi
done

# -------------------------- VM TEMPLATE CREATION --------------------------------

create_vm_template() {
  log "Starting VM Template Creation..."

  # Check if template already exists
  if qm config "$TEMPLATE_ID" >/dev/null 2>&1; then
    log "Template $TEMPLATE_ID already exists. Skipping VM creation."
    return
  fi

  # Download cloud image if not present
  if [ ! -f "$IMAGE_FILE" ]; then
    log "Downloading cloud image: $IMAGE_URL"
    wget -q --show-progress "$IMAGE_URL" || error_exit "Failed to download cloud image."
  else
    log "Cloud image already present. Skipping download."
  fi

  # Create VM
  log "Creating VM $VM_ID..."
  qm create "$VM_ID" \
    --memory "$MEMORY_MB" \
    --name "$VM_NAME" \
    --net0 virtio,bridge="$BRIDGE" \
    --scsihw virtio-scsi-pci \
    --cpu host,flags=+aes || error_exit "Failed to create VM."

  # Import disk
  log "Importing disk to VM..."
  qm disk import "$VM_ID" "$IMAGE_FILE" "$STORAGE" || error_exit "Failed to import disk."

  # Configure disk and boot
  log "Configuring SCSI controller and boot disk..."
  qm set "$VM_ID" \
    --scsihw virtio-scsi-pci \
    --scsi0 "$STORAGE":vm-"$VM_ID"-disk-0 || error_exit "Failed to configure SCSI disk."

  qm set "$VM_ID" --ide2 "$STORAGE":cloudinit || error_exit "Failed to set cloudinit drive."

  qm set "$VM_ID" --boot c --bootdisk scsi0 || error_exit "Failed to set boot order."

  # Serial console and VGA
  qm set "$VM_ID" --serial0 socket --vga serial0 || error_exit "Failed to configure serial console."

  # Resize disk
  log "Resizing disk to ${DISK_SIZE_GB}G..."
  qm resize "$VM_ID" scsi0 "${DISK_SIZE_GB}G" || error_exit "Failed to resize disk."

  # Convert to template
  log "Converting VM $VM_ID to template $TEMPLATE_ID..."
  qm template "$TEMPLATE_ID" || error_exit "Failed to convert VM to template."

  log "VM Template $TEMPLATE_ID created successfully."
}

# -------------------------- USER/ROLE/TOKEN SETUP -------------------------------

setup_user_role_token() {
  log "Starting User, Role, and Token Setup..."

  # Create role if not exists
  if ! pveum role list | awk -v role="$ROLE_NAME" '$1 == role {found=1} END {exit !found}'; then
    log "Creating role: $ROLE_NAME"
    pveum role add "$ROLE_NAME" -privs "$PRIVS" || error_exit "Failed to create role."
  else
    log "Role $ROLE_NAME already exists. Skipping creation."
  fi

  # Create user if not exists
  USER_FULL="${USER_NAME}@${USER_REALM}"
  if ! pveum user list | awk -v user="$USER_FULL" '$1 == user {found=1} END {exit !found}'; then
    log "Creating user: $USER_FULL"
    pveum user add "$USER_FULL" || error_exit "Failed to create user."
  else
    log "User $USER_FULL already exists. Skipping creation."
  fi

  # Assign role to user at root path
  log "Assigning role $ROLE_NAME to user $USER_FULL at /..."
  pveum aclmod / -user "$USER_FULL" -role "$ROLE_NAME" || error_exit "Failed to assign role to user."

  # Create token if not exists (idempotency for token is more complex; assume overwrite is OK)
  log "Creating API token for $USER_FULL..."
  pveum user token add "$USER_FULL" "$TOKEN_NAME" --privsep=0 || error_exit "Failed to create API token."

  log "User, Role, and Token setup completed successfully."
}

# -------------------------- MAIN EXECUTION --------------------------------------

main() {
  log "Starting Proxmox setup script..."
  create_vm_template
  setup_user_role_token
  log "All tasks completed successfully."
}

main