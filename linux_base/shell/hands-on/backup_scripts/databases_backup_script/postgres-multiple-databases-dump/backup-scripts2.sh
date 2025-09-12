#!/bin/bash

# Set main backup root directory and log file
BACKUP_ROOT="/corteza_prod_backups/backups"
LOG_FILE="/var/log/pg_dump_corteza.log"

# Google Chat webhook URL
WEBHOOK_URL="https://chat.googleapis.com/v1/spaces/AAAA9obFQb4/messages?key=AIzaSyDdI0hCZtE6vySjMm-WEfRq3CPzqKqqsHI&token=rteNZk-woz3skEEN1qju1qRl2JO4iixAE7e4M4jnrMQ"

# Create backup root directory if it doesn't exist
mkdir -p "$BACKUP_ROOT"

# Timestamp
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Collect backup results
BACKUP_RESULTS=""

# Define associative array: project => "IP:DB:USER"
declare -A PROJECTS
PROJECTS["corteza_cement_project"]="157.230.192.66:5432:corteza:rootuser"
PROJECTS["corteza_prod_project"]="137.184.250.20:5432:corteza:rootuser"
PROJECTS["corteza_ispats_project"]="139.59.195.106:5432:corteza:rootuser"
# PROJECTS["corteza_alpha_project"]="172.17.17.242:netbox:netbox"
# Add more as needed...

# Loop through projects and run backup
for PROJECT_NAME in "${!PROJECTS[@]}"; do
    IFS=':' read -r IP PORT DB_NAME DB_USER <<< "${PROJECTS[$PROJECT_NAME]}"

    # Create temp backup file
    RAW_BACKUP_FILE="$BACKUP_ROOT/${PROJECT_NAME}_$(date +%F).sql"
    COMPRESSED_BACKUP_FILE="${RAW_BACKUP_FILE}.gz"

    # Run pg_dump
    if pg_dump -U "$DB_USER" -h "$IP" -p "$PORT" -F c -b -v -f "$RAW_BACKUP_FILE" "$DB_NAME" >> "$LOG_FILE" 2>&1; then
        gzip "$RAW_BACKUP_FILE"
        echo "[$TIMESTAMP] ✅ Backup successful and compressed: $COMPRESSED_BACKUP_FILE" >> "$LOG_FILE"
        BACKUP_RESULTS+="✅ Backup succeeded: '$PROJECT_NAME' ($DB_NAME @ $IP)\n"
    else
        echo "[$TIMESTAMP] ❌ Backup failed for $DB_NAME at $IP." >> "$LOG_FILE"
        BACKUP_RESULTS+="❌ Backup failed: '$PROJECT_NAME' ($DB_NAME @ $IP)\n"
        [ -f "$RAW_BACKUP_FILE" ] && rm -f "$RAW_BACKUP_FILE"
    fi
done

# Send Google Chat notification
if [ -n "$BACKUP_RESULTS" ]; then
    curl -s -X POST -H 'Content-Type: application/json' \
         -d "{\"text\": \"Backup Summary ($TIMESTAMP):\n$BACKUP_RESULTS\"}" "$WEBHOOK_URL" > /dev/null
else
    curl -s -X POST -H 'Content-Type: application/json' \
         -d "{\"text\": \"Backup Summary ($TIMESTAMP):\nNo backups attempted.\"}" "$WEBHOOK_URL" > /dev/null
fi

# Clean up old compressed backups (> 7 days)
find "$BACKUP_ROOT" -type f -name "*.sql.gz" -mtime +7 -not -size 0 -exec rm {} \;
