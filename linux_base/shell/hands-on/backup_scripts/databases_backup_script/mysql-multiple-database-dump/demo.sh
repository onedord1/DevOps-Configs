#!/bin/bash

# Database configurations for each project
declare -A DATABASES
DATABASES["ACCOUNTS QA"]="172.17.19.31:3306:accdb"
DATABASES["ACL QA"]="172.17.19.34:3306:acldb"
DATABASES["HR QA"]="172.17.19.29:3306:hrdb"
DATABASES["SCM QA"]="172.17.19.24:3306:scmdb"
DATABASES["CPS QA"]="172.17.19.33:3306:cpsdb"

USER="root"
PASSWORD="superAdmin"
BACKUP_DIR="/home/you/Music/backups"
WEBHOOK_URL="https://chat.googleapis.com/v1/spaces/AAAA9obFQb4/messages?key=AIzaSyDdI0hCZtE6vySjMm-WEfRq3CPzqKqqsHI&token=rteNZk-woz3skEEN1qju1qRl2JO4iixAE7e4M4jnrMQ"

DATE=$(date +"%Y-%m-%d_%H-%M-%S")

# Function to create database dump
backup_database() {
    local project=$1
    local host_port_db=$2
    IFS=":" read -r HOST PORT DB_NAME <<< "$host_port_db"

    DUMP_FILE="${BACKUP_DIR}/${project}_backup_${DATE}.sql.gz"
    # DUMP_FILE="${BACKUP_DIR}/${project}_backup_${DATE}.sql.xz"
    echo "Creating dump for $DB_NAME ($project) at $HOST:$PORT..."
    
    # Dump the database
    # mysqldump -u $USER -p$PASSWORD -h $HOST -P $PORT --databases $DB_NAME --set-gtid-purged=OFF > "$DUMP_FILE"
    mysqldump --triggers --routines -u $USER -p$PASSWORD -h $HOST -P $PORT --databases $DB_NAME --set-gtid-purged=OFF | gzip > "$DUMP_FILE"
    
    if [ $? -eq 0 ]; then
        echo "Dump for $DB_NAME completed successfully."
        return 0
    else
        echo "Dump for $DB_NAME failed!"
        return 1
    fi
}

# Perform backups
SUCCESSFUL_BACKUPS=()

for project in "${!DATABASES[@]}"; do
    if backup_database "$project" "${DATABASES[$project]}"; then
        SUCCESSFUL_BACKUPS+=("$project")
    fi
done

# Send Google Chat notification if successful
if [ ${#SUCCESSFUL_BACKUPS[@]} -gt 0 ]; then
    # MESSAGE="Database Dump Created Successfully ✅: Dump Date \`$(date +"%Y-%m-%d %H:%M:%S")\` for: ${SUCCESSFUL_BACKUPS[*]} Notifications For : @Mehearaz Uddin Himel"
    MESSAGE="QA Databases Dump Created Successfully ✅\nDump Date: \`$(date +"%Y-%m-%d %H:%M:%S")\`\nFor: ${SUCCESSFUL_BACKUPS[*]}\nNotifications For: @Mehearaz Uddin Himel"
    # MESSAGE="Database Dump Created Successfully ✅ Dump Date - $(date +"%Y-%m-%d %H:%M:%S") for: ${SUCCESSFUL_BACKUPS[*]}"
    curl -X POST -H "Content-Type: application/json" -d "{\"text\": \"$MESSAGE\"}" "$WEBHOOK_URL"
else
    MESSAGE="❌ QA Databases Dump Failed on $(date +"%Y-%m-%d %H:%M:%S")"
    curl -X POST -H "Content-Type: application/json" -d "{\"text\": \"$MESSAGE\"}" "$WEBHOOK_URL"
fi
