#!/bin/bash

# Set backup directory and log file
BACKUP_DIR="/netbox-backup/backups"
LOG_FILE="/var/log/pg_dump.log"

# Google Chat webhook URL (replace with your actual webhook URL)
WEBHOOK_URL="https://chat.googleapis.com/v1/spaces/AAAA9obFQb4/messages?key=AIzaSyDdI0hCZtE6vySjMm-WEfRq3CPzqKqqsHI&token=rteNZk-woz3skEEN1qju1qRl2JO4iixAE7e4M4jnrMQ"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Define arrays for IP addresses and database names
IPS=("172.17.17.242")  # Add more IPs as needed
DB_NAMES=("netbox")         # Add more database names as needed

# Timestamp
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Variable to collect backup results
BACKUP_RESULTS=""

# Loop through each IP and database name
for IP in "${IPS[@]}"; do
    for DB_NAME in "${DB_NAMES[@]}"; do
        # Construct backup file name with IP and DB name
        BACKUP_FILE="$BACKUP_DIR/backedup_${DB_NAME}_${IP}_$(date +%F).sql"

        # Run pg_dump for the current IP and database
        if pg_dump -U netbox -h "$IP" -p 5432 -F c -b -v -f "$BACKUP_FILE" "$DB_NAME" >> "$LOG_FILE" 2>&1; then
            echo "[$TIMESTAMP] ✅ Backup successful for $DB_NAME at $IP: $BACKUP_FILE" >> "$LOG_FILE"
            # Append success message to BACKUP_RESULTS
            BACKUP_RESULTS+="✅ Successfully Backuped for database '$DB_NAME' at IP '$IP': $BACKUP_FILE\n"
        else
            echo "[$TIMESTAMP] ❌ Backup failed for $DB_NAME at $IP." >> "$LOG_FILE"
            # Append failure message to BACKUP_RESULTS
            BACKUP_RESULTS+="❌ Failed To Backup for database '$DB_NAME' at IP '$IP'\n"
        fi
    done
done

# Send a single notification to Google Chat with all backup results
if [ -n "$BACKUP_RESULTS" ]; then
    curl -s -X POST -H 'Content-Type: application/json' \
         -d "{\"text\": \"Backup Summary ($TIMESTAMP):\n$BACKUP_RESULTS\"}" "$WEBHOOK_URL" > /dev/null
else
    curl -s -X POST -H 'Content-Type: application/json' \
         -d "{\"text\": \"Backup Summary ($TIMESTAMP):\nNo backups were attempted.\"}" "$WEBHOOK_URL" > /dev/null
fi


# Remove backups older than 7 days, but only if they are not empty (size > 0 bytes)
find "$BACKUP_DIR" -type f -name "backedupnetbox_*.sql" -mtime +7 -not -size 0 -exec rm {} \;