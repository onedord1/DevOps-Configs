#!/bin/bash

BACKUP_JOB_NAME="harbor_backup"
INSTANCE_NAME="$(hostname)"
PUSHGATEWAY_URL="http://localhost:9091"

# Record start time
START_TIME=$(date +%s)

set -e

# Configuration
HARBOR_DIR="/opt/harbor"
DATA_DIR="/data"
BACKUP_DIR="/backup/harbor/"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILENAME="harbor_backup_${TIMESTAMP}.tar.gz"
TEMP_BACKUP_DIR="/backup/harbor_backup_${TIMESTAMP}"
S3_ALIAS="harbor-minio"
S3_BUCKET="harbor-backup"
S3_ENDPOINT="https://172.17.19.252"
S3_ACCESS_KEY="harborbackup"
S3_SECRET_KEY="S3cureHarborPW123!"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
    fi
}

check_harbor_status() {
    cd "$HARBOR_DIR"
    if ! docker compose ps | grep -q "Up"; then
        warning "Harbor containers are not running. Backup will proceed but may be incomplete."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Backup aborted by user."
            exit 1
        fi
    fi
}

create_backup_dir() {
    log "Creating backup directories..."
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$TEMP_BACKUP_DIR"
}

backup_database() {
    log "Backing up PostgreSQL database..."
    cd "$HARBOR_DIR"
    DB_CONTAINER=$(docker compose ps -q postgresql)
    if [ -z "$DB_CONTAINER" ]; then
        error "Harbor database container not found"
    fi
    docker exec "$DB_CONTAINER" pg_dumpall -c -U postgres > "$TEMP_BACKUP_DIR/harbor_database.sql"
    log "Database backup completed"
}

backup_config() {
    log "Backing up Harbor configuration..."
    mkdir -p "$TEMP_BACKUP_DIR/harbor_config"
    cp -r "$HARBOR_DIR/common" "$TEMP_BACKUP_DIR/harbor_config/" 2>/dev/null || true
    cp "$HARBOR_DIR/harbor.yml" "$TEMP_BACKUP_DIR/harbor_config/" 2>/dev/null || true
    cp "$HARBOR_DIR/docker-compose.yml" "$TEMP_BACKUP_DIR/harbor_config/" 2>/dev/null || true
    log "Configuration backup completed"
}

backup_data() {
    log "Backing up Harbor data directory..."
    warning "Stopping database services for data backup..."
    cd "$HARBOR_DIR"
    docker compose stop postgresql redis
    tar -czf "$TEMP_BACKUP_DIR/harbor_data.tar.gz" -C "$(dirname "$DATA_DIR")" "$(basename "$DATA_DIR")"
    docker compose start postgresql redis
    log "Waiting for database services to start..."
    sleep 15
    log "Data backup completed"
}

create_metadata() {
    log "Creating backup metadata..."
    cat > "$TEMP_BACKUP_DIR/backup_info.txt" << EOF
Harbor Backup Information
========================
Backup Date: $(date)
Harbor Directory: $HARBOR_DIR
Data Directory: $DATA_DIR
Backup Created By: $(whoami)
System: $(uname -a)

Harbor Version Information:
$(cd "$HARBOR_DIR" && docker compose images | grep harbor-core | awk '{print $2}' | head -1 2>/dev/null || echo "Version info not available")

Container Status at Backup Time:
$(cd "$HARBOR_DIR" && docker compose ps)
EOF
}

create_final_backup() {
    log "Creating final compressed backup..."
    cd "$TEMP_BACKUP_DIR"
    tar -czf "$BACKUP_DIR/$BACKUP_FILENAME" .
    BACKUP_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_FILENAME" | cut -f1)
    log "Final backup created: $BACKUP_DIR/$BACKUP_FILENAME"
    log "Backup size: $BACKUP_SIZE"
}

upload_to_s3() {
    log "Uploading backup to S3..."
    mc alias set "$S3_ALIAS" "$S3_ENDPOINT" "$S3_ACCESS_KEY" "$S3_SECRET_KEY" --insecure 2>/dev/null || true
    mc cp "$BACKUP_DIR/$BACKUP_FILENAME" "$S3_ALIAS/$S3_BUCKET/" --insecure
    if [ $? -eq 0 ]; then
        log "Backup uploaded to S3 successfully"
    else
        error "Failed to upload backup to S3"
    fi
}

cleanup_old_s3_backups() {
    log "Cleaning up old backups from S3 (keeping latest 3)..."
    mc ls "$S3_ALIAS/$S3_BUCKET/" --insecure | \
        awk '{print $NF}' | grep '^harbor_backup_.*\.tar\.gz$' | sort -r | tail -n +4 | while read -r old_backup; do
            log "Removing old S3 backup: $old_backup"
            mc rm "$S3_ALIAS/$S3_BUCKET/$old_backup" --insecure
        done
}

cleanup_old_backups() {
    log "Cleaning up old local backups (keeping latest 3)..."
    cd "$BACKUP_DIR"
    BACKUP_COUNT=$(ls -1 harbor_backup_*.tar.gz 2>/dev/null | wc -l)
    if [ "$BACKUP_COUNT" -gt 3 ]; then
        ls -1t harbor_backup_*.tar.gz | tail -n +4 | while read -r old_backup; do
            log "Removing old local backup: $old_backup"
            rm -f "$old_backup"
        done
    fi
}

cleanup() {
    log "Cleaning up temporary files..."
    rm -rf "$TEMP_BACKUP_DIR"
}

main() {
    log "Starting Harbor backup process..."
    check_root
    check_harbor_status
    create_backup_dir
    backup_database
    backup_config
    backup_data
    create_metadata
    create_final_backup
    upload_to_s3
    cleanup_old_s3_backups
    cleanup_old_backups
    cleanup
    log "Harbor backup completed successfully!"
    log "Backup file: $BACKUP_DIR/$BACKUP_FILENAME"
}

trap cleanup EXIT
main "$@"
STATUS=$?


# Record end time
END_TIME=$(date +%s)

# Check if Pushgateway is available
if curl --silent --fail "$PUSHGATEWAY_URL/metrics"; then
    # Push metrics to Pushgateway
    cat <<EOF | curl --silent --show-error --fail --data-binary @- "$PUSHGATEWAY_URL/metrics/job/$BACKUP_JOB_NAME/instance/$INSTANCE_NAME"
# TYPE backup_job_success gauge
backup_job_success $((1 - $STATUS))
# TYPE backup_job_last_run_seconds gauge
backup_job_last_run_seconds $END_TIME
# TYPE backup_job_duration_seconds gauge
backup_job_duration_seconds $((END_TIME - START_TIME))
EOF
else
    echo "Pushgateway not reachable at $PUSHGATEWAY_URL. Skipping metrics push."
fi

exit $STATUS