#!/bin/bash

set -euo pipefail  # Exit on error, unset vars, pipe failures

# -------------------------- SCRIPT PARAMETERS -----------------------------------

# Default values
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DEFAULT_CONFIG_DIR="$PROJECT_ROOT/config"
DEFAULT_ENVIRONMENT="dev"
ENVIRONMENT="${ENVIRONMENT:-$DEFAULT_ENVIRONMENT}"
CONFIG_DIR="${CONFIG_DIR:-$DEFAULT_CONFIG_DIR}"

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --env) ENVIRONMENT="$2"; shift ;;
        --config-dir) CONFIG_DIR="$2"; shift ;;
        --help) 
            echo "Usage: $0 [--env ENVIRONMENT] [--config-dir PATH]"
            echo "  --env ENVIRONMENT     Environment to use (dev, staging, prod)"
            echo "  --config-dir PATH     Path to configuration directory"
            exit 0
            ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Configuration file paths
DEFAULT_CONFIG_FILE="$CONFIG_DIR/default.yaml"
ENV_CONFIG_FILE="$CONFIG_DIR/$ENVIRONMENT.yaml"
ENV_FILE="$PROJECT_ROOT/.env"

# -------------------------- HELPER FUNCTIONS ------------------------------------

log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Log to console
    echo "[$timestamp] [$level] $message"
    
    # Log to file if configured
    if [[ -n "${LOG_FILE:-}" ]]; then
        echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    fi
}

error_exit() {
    log "ERROR" "$1"
    exit 1
}

# Load environment variables from .env file if it exists
load_env() {
    if [[ -f "$ENV_FILE" ]]; then
        log "INFO" "Loading environment variables from $ENV_FILE"
        set -a
        source "$ENV_FILE"
        set +a
    else
        log "WARN" "No .env file found at $ENV_FILE"
    fi
}

# Check if required command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Validate required commands
validate_commands() {
    local required_commands=("yq" "qm" "pveum" "wget")
    for cmd in "${required_commands[@]}"; do
        if ! command_exists "$cmd"; then
            error_exit "Required command '$cmd' is not installed or not in PATH."
        fi
    done
}

# Validate configuration values
validate_config() {
    log "INFO" "Validating configuration"
    
    # Validate VM ID is a number
    if ! [[ "$VM_ID" =~ ^[0-9]+$ ]]; then
        error_exit "VM ID must be a number: $VM_ID"
    fi
    
    # Validate Template ID is a number
    if ! [[ "$TEMPLATE_ID" =~ ^[0-9]+$ ]]; then
        error_exit "Template ID must be a number: $TEMPLATE_ID"
    fi
    
    # Validate Memory is a number and reasonable
    if ! [[ "$MEMORY_MB" =~ ^[0-9]+$ ]] || [[ "$MEMORY_MB" -lt 512 ]]; then
        error_exit "Memory must be a number >= 512: $MEMORY_MB"
    fi
    
    # Validate Disk Size is a number and reasonable
    if ! [[ "$DISK_SIZE_GB" =~ ^[0-9]+$ ]] || [[ "$DISK_SIZE_GB" -lt 1 ]]; then
        error_exit "Disk size must be a number >= 1: $DISK_SIZE_GB"
    fi
    
    # Validate Bridge exists
    if ! ip link show "$BRIDGE" >/dev/null 2>&1; then
        log "WARN" "Network bridge $BRIDGE does not exist. This may cause VM creation to fail."
    fi
    
    # Validate Storage exists
    if ! pvesm list "$STORAGE" >/dev/null 2>&1; then
        log "WARN" "Storage $STORAGE does not exist. This may cause VM creation to fail."
    fi
    
    log "INFO" "Configuration validation completed successfully"
}

# Load configuration from YAML files
load_config() {
    log "INFO" "Loading configuration from $DEFAULT_CONFIG_FILE"
    
    # Check if yq is installed
    if ! command_exists yq; then
        error_exit "yq is required for parsing YAML configuration files. Please install it."
    fi
    
    # Check if default config file exists
    if [[ ! -f "$DEFAULT_CONFIG_FILE" ]]; then
        error_exit "Default configuration file not found: $DEFAULT_CONFIG_FILE"
    fi
    
    # Load default configuration
    VM_ID=$(yq '.vm.id' "$DEFAULT_CONFIG_FILE")
    TEMPLATE_ID=$(yq '.vm.template_id' "$DEFAULT_CONFIG_FILE")
    VM_NAME=$(yq '.vm.name' "$DEFAULT_CONFIG_FILE")
    MEMORY_MB=$(yq '.vm.memory_mb' "$DEFAULT_CONFIG_FILE")
    DISK_SIZE_GB=$(yq '.vm.disk_size_gb' "$DEFAULT_CONFIG_FILE")
    IMAGE_FILE=$(yq '.vm.image_file' "$DEFAULT_CONFIG_FILE")
    IMAGE_URL=$(yq '.vm.image_url' "$DEFAULT_CONFIG_FILE")
    STORAGE=$(yq '.vm.storage' "$DEFAULT_CONFIG_FILE")
    BRIDGE=$(yq '.vm.bridge' "$DEFAULT_CONFIG_FILE")
    USER_NAME=$(yq '.user.name' "$DEFAULT_CONFIG_FILE")
    USER_REALM=$(yq '.user.realm' "$DEFAULT_CONFIG_FILE")
    ROLE_NAME=$(yq '.user.role_name' "$DEFAULT_CONFIG_FILE")
    TOKEN_NAME=$(yq '.user.token_name' "$DEFAULT_CONFIG_FILE")
    
    # Convert YAML array to space-separated string for privileges
    PRIVS=$(yq '.user.privs | join(" ")' "$DEFAULT_CONFIG_FILE")
    
    # Load logging configuration
    LOG_LEVEL=$(yq '.logging.level' "$DEFAULT_CONFIG_FILE")
    LOG_FILE=$(yq '.logging.file' "$DEFAULT_CONFIG_FILE")
    
    # Override with environment-specific configuration if it exists
    if [[ -f "$ENV_CONFIG_FILE" ]]; then
        log "INFO" "Loading environment-specific configuration from $ENV_CONFIG_FILE"
        
        # Override VM configuration
        local env_vm_id=$(yq '.vm.id' "$ENV_CONFIG_FILE")
        if [[ "$env_vm_id" != "null" ]]; then VM_ID="$env_vm_id"; fi
        
        local env_template_id=$(yq '.vm.template_id' "$ENV_CONFIG_FILE")
        if [[ "$env_template_id" != "null" ]]; then TEMPLATE_ID="$env_template_id"; fi
        
        local env_vm_name=$(yq '.vm.name' "$ENV_CONFIG_FILE")
        if [[ "$env_vm_name" != "null" ]]; then VM_NAME="$env_vm_name"; fi
        
        local env_memory_mb=$(yq '.vm.memory_mb' "$ENV_CONFIG_FILE")
        if [[ "$env_memory_mb" != "null" ]]; then MEMORY_MB="$env_memory_mb"; fi
        
        local env_disk_size_gb=$(yq '.vm.disk_size_gb' "$ENV_CONFIG_FILE")
        if [[ "$env_disk_size_gb" != "null" ]]; then DISK_SIZE_GB="$env_disk_size_gb"; fi
        
        local env_image_file=$(yq '.vm.image_file' "$ENV_CONFIG_FILE")
        if [[ "$env_image_file" != "null" ]]; then IMAGE_FILE="$env_image_file"; fi
        
        local env_image_url=$(yq '.vm.image_url' "$ENV_CONFIG_FILE")
        if [[ "$env_image_url" != "null" ]]; then IMAGE_URL="$env_image_url"; fi
        
        local env_storage=$(yq '.vm.storage' "$ENV_CONFIG_FILE")
        if [[ "$env_storage" != "null" ]]; then STORAGE="$env_storage"; fi
        
        local env_bridge=$(yq '.vm.bridge' "$ENV_CONFIG_FILE")
        if [[ "$env_bridge" != "null" ]]; then BRIDGE="$env_bridge"; fi
        
        # Override user configuration
        local env_user_name=$(yq '.user.name' "$ENV_CONFIG_FILE")
        if [[ "$env_user_name" != "null" ]]; then USER_NAME="$env_user_name"; fi
        
        local env_user_realm=$(yq '.user.realm' "$ENV_CONFIG_FILE")
        if [[ "$env_user_realm" != "null" ]]; then USER_REALM="$env_user_realm"; fi
        
        local env_role_name=$(yq '.user.role_name' "$ENV_CONFIG_FILE")
        if [[ "$env_role_name" != "null" ]]; then ROLE_NAME="$env_role_name"; fi
        
        local env_token_name=$(yq '.user.token_name' "$ENV_CONFIG_FILE")
        if [[ "$env_token_name" != "null" ]]; then TOKEN_NAME="$env_token_name"; fi
        
        local env_privs=$(yq '.user.privs | join(" ")' "$ENV_CONFIG_FILE")
        if [[ "$env_privs" != "null" ]]; then PRIVS="$env_privs"; fi
        
        # Override logging configuration
        local env_log_level=$(yq '.logging.level' "$ENV_CONFIG_FILE")
        if [[ "$env_log_level" != "null" ]]; then LOG_LEVEL="$env_log_level"; fi
        
        local env_log_file=$(yq '.logging.file' "$ENV_CONFIG_FILE")
        if [[ "$env_log_file" != "null" ]]; then LOG_FILE="$env_log_file"; fi
    fi
    
    # Override with environment variables if they exist
    # This allows for secrets and other sensitive data to be passed securely
    VM_ID=${VM_ID_OVERRIDE:-$VM_ID}
    TEMPLATE_ID=${TEMPLATE_ID_OVERRIDE:-$TEMPLATE_ID}
    VM_NAME=${VM_NAME_OVERRIDE:-$VM_NAME}
    MEMORY_MB=${MEMORY_MB_OVERRIDE:-$MEMORY_MB}
    DISK_SIZE_GB=${DISK_SIZE_GB_OVERRIDE:-$DISK_SIZE_GB}
    IMAGE_FILE=${IMAGE_FILE_OVERRIDE:-$IMAGE_FILE}
    IMAGE_URL=${IMAGE_URL_OVERRIDE:-$IMAGE_URL}
    STORAGE=${STORAGE_OVERRIDE:-$STORAGE}
    BRIDGE=${BRIDGE_OVERRIDE:-$BRIDGE}
    USER_NAME=${USER_NAME_OVERRIDE:-$USER_NAME}
    USER_REALM=${USER_REALM_OVERRIDE:-$USER_REALM}
    ROLE_NAME=${ROLE_NAME_OVERRIDE:-$ROLE_NAME}
    TOKEN_NAME=${TOKEN_NAME_OVERRIDE:-$TOKEN_NAME}
    PRIVS=${PRIVS_OVERRIDE:-$PRIVS}
    LOG_LEVEL=${LOG_LEVEL_OVERRIDE:-$LOG_LEVEL}
    LOG_FILE=${LOG_FILE_OVERRIDE:-$LOG_FILE}
    
    log "INFO" "Configuration loaded successfully for environment: $ENVIRONMENT"
}

# Print current configuration (excluding sensitive data)
print_config() {
    log "INFO" "Current configuration:"
    log "INFO" "  Environment: $ENVIRONMENT"
    log "INFO" "  VM ID: $VM_ID"
    log "INFO" "  Template ID: $TEMPLATE_ID"
    log "INFO" "  VM Name: $VM_NAME"
    log "INFO" "  Memory: $MEMORY_MB MB"
    log "INFO" "  Disk Size: $DISK_SIZE_GB GB"
    log "INFO" "  Image File: $IMAGE_FILE"
    log "INFO" "  Image URL: $IMAGE_URL"
    log "INFO" "  Storage: $STORAGE"
    log "INFO" "  Bridge: $BRIDGE"
    log "INFO" "  User Name: $USER_NAME"
    log "INFO" "  User Realm: $USER_REALM"
    log "INFO" "  Role Name: $ROLE_NAME"
    log "INFO" "  Token Name: $TOKEN_NAME"
    log "INFO" "  Log Level: $LOG_LEVEL"
    log "INFO" "  Log File: $LOG_FILE"
}

# -------------------------- VM TEMPLATE CREATION --------------------------------

create_vm_template() {
    log "INFO" "Starting VM Template Creation..."

    # Check if template already exists
    if qm config "$TEMPLATE_ID" >/dev/null 2>&1; then
        log "INFO" "Template $TEMPLATE_ID already exists. Skipping VM creation."
        return
    fi

    # Download cloud image if not present
    if [ ! -f "$IMAGE_FILE" ]; then
        log "INFO" "Downloading cloud image: $IMAGE_URL"
        wget -q --show-progress "$IMAGE_URL" || error_exit "Failed to download cloud image."
    else
        log "INFO" "Cloud image already present. Skipping download."
    fi

    # Create VM
    log "INFO" "Creating VM $VM_ID..."
    qm create "$VM_ID" \
        --memory "$MEMORY_MB" \
        --name "$VM_NAME" \
        --net0 virtio,bridge="$BRIDGE" \
        --scsihw virtio-scsi-pci \
        --cpu host,flags=+aes || error_exit "Failed to create VM."

    # Import disk
    log "INFO" "Importing disk to VM..."
    qm disk import "$VM_ID" "$IMAGE_FILE" "$STORAGE" || error_exit "Failed to import disk."

    # Configure disk and boot
    log "INFO" "Configuring SCSI controller and boot disk..."
    qm set "$VM_ID" \
        --scsihw virtio-scsi-pci \
        --scsi0 "$STORAGE":vm-"$VM_ID"-disk-0 || error_exit "Failed to configure SCSI disk."

    qm set "$VM_ID" --ide2 "$STORAGE":cloudinit || error_exit "Failed to set cloudinit drive."

    qm set "$VM_ID" --boot c --bootdisk scsi0 || error_exit "Failed to set boot order."

    # Serial console and VGA
    qm set "$VM_ID" --serial0 socket --vga serial0 || error_exit "Failed to configure serial console."

    # Resize disk
    log "INFO" "Resizing disk to ${DISK_SIZE_GB}G..."
    qm resize "$VM_ID" scsi0 "${DISK_SIZE_GB}G" || error_exit "Failed to resize disk."

    # Convert to template
    log "INFO" "Converting VM $VM_ID to template $TEMPLATE_ID..."
    qm template "$TEMPLATE_ID" || error_exit "Failed to convert VM to template."

    log "INFO" "VM Template $TEMPLATE_ID created successfully."
}

# -------------------------- USER/ROLE/TOKEN SETUP -------------------------------

setup_user_role_token() {
    log "INFO" "Starting User, Role, and Token Setup..."

    # Create role if not exists
    if ! pveum role list | awk -v role="$ROLE_NAME" '$1 == role {found=1} END {exit !found}'; then
        log "INFO" "Creating role: $ROLE_NAME"
        pveum role add "$ROLE_NAME" -privs "$PRIVS" || error_exit "Failed to create role."
    else
        log "INFO" "Role $ROLE_NAME already exists. Skipping creation."
    fi

    # Create user if not exists
    USER_FULL="${USER_NAME}@${USER_REALM}"
    if ! pveum user list | awk -v user="$USER_FULL" '$1 == user {found=1} END {exit !found}'; then
        log "INFO" "Creating user: $USER_FULL"
        pveum user add "$USER_FULL" || error_exit "Failed to create user."
    else
        log "INFO" "User $USER_FULL already exists. Skipping creation."
    fi

    # Assign role to user at root path
    log "INFO" "Assigning role $ROLE_NAME to user $USER_FULL at /..."
    pveum aclmod / -user "$USER_FULL" -role "$ROLE_NAME" || error_exit "Failed to assign role to user."

    # Create token and capture the output
    log "INFO" "Creating API token for $USER_FULL..."
    TOKEN_OUTPUT=$(pveum user token add "$USER_FULL" "$TOKEN_NAME" --privsep=0) || error_exit "Failed to create API token."
    
    # Extract the token secret (UUID) from the output
    TOKEN_SECRET=$(echo "$TOKEN_OUTPUT" | grep -oP '(?<=UUID: )\S+')
    
    if [[ -z "$TOKEN_SECRET" ]]; then
        error_exit "Failed to extract token secret from output."
    fi
    
    # Display token information in a format suitable for Terraform
    log "INFO" "User, Role, and Token setup completed successfully."
    echo ""
    echo "=============================================================="
    echo "TERRAFORM CONFIGURATION"
    echo "=============================================================="
    echo "# Add this to your terraform.tfvars file:"
    echo "pm_user = \"$USER_FULL\""
    echo "pm_token = \"$TOKEN_SECRET\""
    echo "pm_api_url = \"https://<ThisHostIP>:8006/api2/json\""
    echo "=============================================================="
    echo ""
}

# -------------------------- MAIN EXECUTION --------------------------------------

main() {
    log "INFO" "Starting Proxmox setup script for environment: $ENVIRONMENT"
    
    # Load environment variables
    load_env
    
    # Validate required commands
    validate_commands
    
    # Load configuration
    load_config
    
    # Print current configuration
    print_config
    
    # Validate configuration
    validate_config
    
    # Create VM template
    create_vm_template
    
    # Setup user, role, and token
    setup_user_role_token
    
    log "INFO" "All tasks completed successfully."
}

# Run main function
main "$@"