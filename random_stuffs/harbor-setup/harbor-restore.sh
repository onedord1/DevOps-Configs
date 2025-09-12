#!/bin/bash

set -euo pipefail

echo "Script started at $(date)"
echo "Arguments: $*"

# Harbor configuration
HARBOR_DIR="/opt/harbor"
DATA_DIR="/data"
BACKUP_DIR="/backup/harbor/"
TEMP_RESTORE_DIR="/backup/harbor_restore_$(date +%s)"
MC_ALIAS="harbor-minio"

MINIO_ENDPOINT=https://172.17.19.252
MINIO_ACCESS_KEY=harborbackup
MINIO_SECRET_KEY=S3cureHarborPW123!
BUCKET_NAME=harbor-backup

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log helpers
log() { echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"; }
error() { echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" >&2; }
warning() { echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"; }
info() { echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] INFO:${NC} $1"; }

usage() {
    echo "Usage: $0 <backup_path_or_s3_uri>"
    echo "Example: $0 /opt/harbor/backups/harbor_backup_20250528_124542.tar.gz"
    echo "         $0 s3://harbor_backup_20250528_124542.tar.gz"
    exit 1
}

check_root() {
    [[ $EUID -ne 0 ]] && error "Run as root" && exit 1
    log "Running as root: confirmed"
}

validate_backup() {
    local file="$1"
    [[ ! -f "$file" ]] && error "Backup not found: $file" && exit 1
    [[ ! "$file" =~ \.tar\.gz$ ]] && error "Must be a .tar.gz file" && exit 1
    if ! tar -tzf "$file" >/dev/null 2>&1; then
        error "Corrupted or invalid backup archive"
        exit 1
    fi
    log "Backup file validation successful: $file"
}

download_from_s3() {
    local s3_path="$1"
    local file_name
    file_name=$(basename "$s3_path")
    local local_path="$BACKUP_DIR/$file_name"

    log "Preparing to download from S3: $s3_path"
    mkdir -p "$BACKUP_DIR"
    log "Backup dir: $BACKUP_DIR"

    if ! mc alias list | grep -q "$MC_ALIAS"; then
        log "Setting MinIO alias..."
        mc alias set "$MC_ALIAS" "$MINIO_ENDPOINT" "$MINIO_ACCESS_KEY" "$MINIO_SECRET_KEY" --insecure
    fi

    log "Downloading backup from S3 to: $local_path"
    mc cp --insecure "$MC_ALIAS/$BUCKET_NAME/$file_name" "$local_path" || {
        error "Failed to download from S3"
        exit 1
    }

    [[ ! -f "$local_path" ]] && {
        error "Download did not complete successfully"
        exit 1
    }

    log "Backup successfully downloaded to $local_path"
    echo "$local_path"
}

extract_backup() {
    local file="$1"
    log "Extracting backup to: $TEMP_RESTORE_DIR"
    mkdir -p "$TEMP_RESTORE_DIR"
    tar -xzf "$file" -C "$TEMP_RESTORE_DIR"
    log "Extraction complete"
}

show_backup_info() {
    if [[ -f "$TEMP_RESTORE_DIR/backup_info.txt" ]]; then
        info "Backup Info:"
        cat "$TEMP_RESTORE_DIR/backup_info.txt"
        echo
        log "Proceeding with restore (automated mode)"
    else
        log "No backup info found"
    fi
}

stop_harbor() {
    log "Stopping Harbor..."
    if [[ -d "$HARBOR_DIR" ]]; then
        cd "$HARBOR_DIR"
        docker compose down || true
    fi
    sleep 10
}

backup_current() {
    local backup_now="/opt/harbor/pre_restore_backup_$(date +%s)"
    mkdir -p "$backup_now"
    warning "Backing up current installation to $backup_now"

    [[ -d "$HARBOR_DIR" ]] && cp -r "$HARBOR_DIR" "$backup_now/harbor_old" || true
    [[ -d "$DATA_DIR" ]] && tar -czf "$backup_now/data_old.tar.gz" -C "$(dirname "$DATA_DIR")" "$(basename "$DATA_DIR")" || true
}

restore_config() {
    log "Restoring configuration..."
    [[ -d "$TEMP_RESTORE_DIR/harbor_config" ]] || { warning "No config found."; return; }
    mkdir -p "$HARBOR_DIR"
    cp -r "$TEMP_RESTORE_DIR/harbor_config/"* "$HARBOR_DIR/" || true
    log "Configuration restored"
}

restore_data() {
    log "Restoring data..."
    [[ -f "$TEMP_RESTORE_DIR/harbor_data.tar.gz" ]] || { error "Data archive missing."; exit 1; }

    [[ -d "$DATA_DIR" ]] && rm -rf "$DATA_DIR"
    tar -xzf "$TEMP_RESTORE_DIR/harbor_data.tar.gz" -C "$(dirname "$DATA_DIR")"
    log "Data restore complete"
}

restore_database() {
    log "Starting DB container..."
    cd "$HARBOR_DIR"
    docker compose up -d postgresql

    log "Waiting for DB..."
    for i in {1..30}; do
        if docker compose exec -T postgresql pg_isready -U postgres >/dev/null 2>&1; then
            break
        fi
        sleep 2
    done

    [[ -f "$TEMP_RESTORE_DIR/harbor_database.sql" ]] || {
        error "Database SQL file missing"
        exit 1
    }

    DB_CONTAINER=$(docker compose ps -q postgresql)
    docker exec -i "$DB_CONTAINER" psql -U postgres < "$TEMP_RESTORE_DIR/harbor_database.sql"
    log "Database restored"
}

start_harbor() {
    log "Starting Harbor..."
    cd "$HARBOR_DIR"
    docker compose up -d
    sleep 60

    if docker compose ps | grep -q "Up"; then
        log "Harbor started successfully"
    else
        warning "Some services may not have started correctly"
        docker compose ps
    fi
}

cleanup() {
    [[ -d "$TEMP_RESTORE_DIR" ]] && {
        log "Cleaning up temporary files..."
        rm -rf "$TEMP_RESTORE_DIR"
    }
}

main() {
    local input="${1:-}"
    [[ -z "$input" ]] && usage

    check_root

    if [[ "$input" =~ ^s3:// ]]; then
        input=$(download_from_s3 "$input")
    fi

    validate_backup "$input"
    extract_backup "$input"
    show_backup_info

    warning "This will replace the current Harbor installation!"
    log "Proceeding with restore (automated mode)"

    backup_current
    stop_harbor
    restore_config
    restore_data
    restore_database
    start_harbor

    log "✅ Restore complete!"
    docker compose -f "$HARBOR_DIR/docker-compose.yml" ps
}

trap cleanup EXIT
case "${1:-}" in
    -h|--help) usage ;;
    *) main "$@" ;;
esac
