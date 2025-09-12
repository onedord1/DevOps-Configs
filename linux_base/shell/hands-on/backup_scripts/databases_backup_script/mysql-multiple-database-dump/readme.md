
# **Automated MySQL Database Backup Script with Google Chat Notifications**

## **Overview**
This guide explains how to automate **MySQL database backups** for multiple projects, compress them using `gzip`, and send a **Google Chat notification** upon successful completion. The script runs daily at **6 PM GMT+6** using `cron`.

---

## **1. Prerequisites**
Ensure your system has:
- **MySQL client tools (`mysqldump`)**
- **Bash shell**
- **`cron` enabled**
- **Google Chat webhook configured**

---

## **2. Backup Script (`backup_databases.sh`)**
Create and edit the script:

```bash
#!/bin/bash

# Database configurations (Project Name -> Host:Port:Database)
declare -A DATABASES
DATABASES["ACCOUNTS QA"]="172.17.19.31:3306:accdb"
DATABASES["ACL QA"]="172.17.19.34:3306:acldb"
DATABASES["HR QA"]="172.17.19.29:3306:hrdb"
DATABASES["SCM QA"]="172.17.19.24:3306:scmdb"
DATABASES["CPS QA"]="172.17.19.33:3306:cpsdb"

USER="root"
PASSWORD="superAdmin"
BACKUP_DIR="/home/you/Music/backups"
WEBHOOK_URL="https://chat.googleapis.com/v1/spaces/AAAA9obFQb4/messages?key=YOUR_KEY&token=YOUR_TOKEN"

DATE=$(date +"%Y-%m-%d_%H-%M-%S")

# Function to create a database dump
backup_database() {
    local project=$1
    local host_port_db=$2
    IFS=":" read -r HOST PORT DB_NAME <<< "$host_port_db"

    DUMP_FILE="${BACKUP_DIR}/${project}_backup_${DATE}.sql.gz"
    echo "Creating dump for $DB_NAME ($project) at $HOST:$PORT..."

    # Dump the database and compress using gzip
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
    MESSAGE="QA Databases Dump Created Successfully ✅\nDump Date: \`$(date +"%Y-%m-%d %H:%M:%S")\`\nFor: ${SUCCESSFUL_BACKUPS[*]}\nNotifications For: @Mehearaz Uddin Himel"
    curl -X POST -H "Content-Type: application/json" -d "{\"text\": \"$MESSAGE\"}" "$WEBHOOK_URL"
else
    MESSAGE="❌ QA Databases Dump Failed on $(date +"%Y-%m-%d %H:%M:%S")"
    curl -X POST -H "Content-Type: application/json" -d "{\"text\": \"$MESSAGE\"}" "$WEBHOOK_URL"
fi
```

---

## **3. Make the Script Executable**
Run:
```bash
chmod +x /path/to/backup_databases.sh
```

---

## **4. Schedule the Script Using Cron**
Edit the crontab:
```bash
crontab -e
```
Add the following line to run the script **every day at 6 PM (GMT+6):**
```bash
0 18 * * * /bin/bash /path/to/backup_databases.sh >> /path/to/logfile.log 2>&1
```

---

## **5. Verify Cron Job Execution**
Check if the cron job is added:
```bash
crontab -l
```
Check logs:
```bash
grep CRON /var/log/syslog
```
or
```bash
journalctl -u cron --since "1 hour ago"
```

---

## **6. Google Chat Webhook Configuration**
To send notifications to Google Chat:
1. **Create a space** in Google Chat.
2. **Go to space settings** → Manage Webhooks.
3. **Create a new webhook**, give it a name.
4. Copy the **Webhook URL** and replace `WEBHOOK_URL` in the script.

---

## **7. Restore a Database (if needed)**
To restore a database from a backup:
```bash
gunzip -c /home/you/Music/backups/hr_backup_YYYY-MM-DD_HH-MM-SS.sql.gz | mysql -u root -p -h 172.17.19.29 -P 3306 hrdb
```

---

## **8. Additional Enhancements**
- Enable **log rotation** for the backup directory.
- Encrypt backup files using **GPG** for extra security.
- Upload backups to **Google Drive / AWS S3**.

---

## **9. Conclusion**
This setup ensures:
✅ **Automated backups** every day  
✅ **Compressed storage** with `gzip`  
✅ **Google Chat notifications** for monitoring  

🚀 Now, your **MySQL databases** are automatically backed up & monitored! 🚀# **Automated MySQL Database Backup Script with Google Chat Notifications**

## **Overview**
This guide explains how to automate **MySQL database backups** for multiple projects, compress them using `gzip`, and send a **Google Chat notification** upon successful completion. The script runs daily at **6 PM GMT+6** using `cron`.

---

## **1. Prerequisites**
Ensure your system has:
- **MySQL client tools (`mysqldump`)**
- **Bash shell**
- **`cron` enabled**
- **Google Chat webhook configured**

---

## **2. Backup Script (`backup_databases.sh`)**
Create and edit the script:

```bash
#!/bin/bash

# Database configurations (Project Name -> Host:Port:Database)
declare -A DATABASES
DATABASES["ACCOUNTS QA"]="172.17.19.31:3306:accdb"
DATABASES["ACL QA"]="172.17.19.34:3306:acldb"
DATABASES["HR QA"]="172.17.19.29:3306:hrdb"
DATABASES["SCM QA"]="172.17.19.24:3306:scmdb"
DATABASES["CPS QA"]="172.17.19.33:3306:cpsdb"

USER="root"
PASSWORD="superAdmin"
BACKUP_DIR="/home/you/Music/backups"
WEBHOOK_URL="https://chat.googleapis.com/v1/spaces/AAAA9obFQb4/messages?key=YOUR_KEY&token=YOUR_TOKEN"

DATE=$(date +"%Y-%m-%d_%H-%M-%S")

# Function to create a database dump
backup_database() {
    local project=$1
    local host_port_db=$2
    IFS=":" read -r HOST PORT DB_NAME <<< "$host_port_db"

    DUMP_FILE="${BACKUP_DIR}/${project}_backup_${DATE}.sql.gz"
    echo "Creating dump for $DB_NAME ($project) at $HOST:$PORT..."

    # Dump the database and compress using gzip
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
    MESSAGE="QA Databases Dump Created Successfully ✅\nDump Date: \`$(date +"%Y-%m-%d %H:%M:%S")\`\nFor: ${SUCCESSFUL_BACKUPS[*]}\nNotifications For: @Mehearaz Uddin Himel"
    curl -X POST -H "Content-Type: application/json" -d "{\"text\": \"$MESSAGE\"}" "$WEBHOOK_URL"
else
    MESSAGE="❌ QA Databases Dump Failed on $(date +"%Y-%m-%d %H:%M:%S")"
    curl -X POST -H "Content-Type: application/json" -d "{\"text\": \"$MESSAGE\"}" "$WEBHOOK_URL"
fi
```

---

## **3. Make the Script Executable**
Run:
```bash
chmod +x /path/to/backup_databases.sh
```

---

## **4. Schedule the Script Using Cron**
Edit the crontab:
```bash
crontab -e
```
Add the following line to run the script **every day at 6 PM (GMT+6):**
```bash
0 18 * * * /bin/bash /path/to/backup_databases.sh >> /path/to/logfile.log 2>&1
```

---

## **5. Verify Cron Job Execution**
Check if the cron job is added:
```bash
crontab -l
```
Check logs:
```bash
grep CRON /var/log/syslog
```
or
```bash
journalctl -u cron --since "1 hour ago"
```

---

## **6. Google Chat Webhook Configuration**
To send notifications to Google Chat:
1. **Create a space** in Google Chat.
2. **Go to space settings** → Manage Webhooks.
3. **Create a new webhook**, give it a name.
4. Copy the **Webhook URL** and replace `WEBHOOK_URL` in the script.

---

## **7. Restore a Database (if needed)**
To restore a database from a backup:
```bash
gunzip -c /home/you/Music/backups/hr_backup_YYYY-MM-DD_HH-MM-SS.sql.gz | mysql -u root -p -h 172.17.19.29 -P 3306 hrdb
```

---

## **9. Conclusion**
This setup ensures:
✅ **Automated backups** every day  
✅ **Compressed storage** with `gzip`  
✅ **Google Chat notifications** for monitoring  

🚀 Now, your **MySQL databases** are automatically backed up & monitored! 🚀