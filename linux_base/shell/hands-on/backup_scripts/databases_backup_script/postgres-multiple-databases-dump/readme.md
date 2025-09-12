# PostgreSQL Database Backup Script Setup Guide

This guide explains how to set up and use a Bash script that backs up PostgreSQL databases, sends notifications to Google Chat, and manages old backup files. The script is designed to be simple to use, even for beginners. Follow these steps to get started. You can use both scrpits since they have same functionality its all about preferences.

## What This Script Does
- Backs up PostgreSQL databases from specified IP addresses and database names.
- Saves backup files to a designated folder (`/netbox-backup/backups`).
- Deletes backup files older than 7 days (but keeps empty files to avoid accidental deletion).
- Sends a single notification to a Google Chat space summarizing all backup results (success or failure).
- Logs all actions to a log file (`/var/log/pg_dump.log`) for troubleshooting.

## Prerequisites
Before you begin, ensure you have:
- A Linux server (e.g., Ubuntu, CentOS) with Bash installed.
- PostgreSQL client tools (`pg_dump`) installed on the server.
- Access to the PostgreSQL databases you want to back up.
- A Google Chat space where you can send notifications.
- Basic command-line knowledge (don’t worry, we’ll guide you!).

## Step-by-Step Setup

### 1. Install Required Tools
The script uses `pg_dump` to back up PostgreSQL databases and `curl` to send notifications to Google Chat. Install these tools if they’re not already on your server.

#### On Ubuntu/Debian:
1. Open a terminal on your server.
2. Run these commands to install `postgresql-client` (for `pg_dump`) and `curl`:
   ```bash
   sudo apt update
   sudo apt install postgresql-client curl
   ```

#### On CentOS/RHEL:
1. Open a terminal on your server.
2. Run these commands:
   ```bash
   sudo yum install postgresql curl
   ```

3. Verify the installations:
   ```bash
   pg_dump --version
   curl --version
   ```
   If both commands show version information, you’re good to go!

### 2. Create a Google Chat Webhook
The script sends backup notifications to a Google Chat space. You need to create a webhook URL for this.

1. Open Google Chat (via a web browser or app).
2. Go to the space (chat room) where you want notifications.
3. Click the space name at the top, then select **Apps & Integrations**.
4. Click **Manage Webhooks**.
5. Click **Add Webhook**, give it a name (e.g., "Backup Notifications"), and click **Save**.
6. Copy the webhook URL (it looks like `https://chat.googleapis.com/v1/spaces/...`).
7. Save this URL somewhere safe—you’ll need it for the script.

### 3. Set Up the Script
The script is a Bash file that you’ll create and configure.

#### Create the Script File
1. Open a terminal on your server.
2. Create a file called `backup_postgres.sh`:
   ```bash
   nano backup_postgres.sh
   ```
3. Copy and paste the following script into the editor:
   ```bash
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

   # Remove backups older than 7 days, but only if they are not empty ( Distance Learning Platformsize > 0 bytes)
   find "$BACKUP_DIR" -type f -name "backedup_*_*.sql" -mtime +7 -not -size 0 -exec rm {} \;
   ```
4. Replace the `WEBHOOK_URL` value with the webhook URL you copied from Google Chat.
5. Configure the `IPS` and `DB_NAMES` arrays:
   - `IPS`: Add the IP addresses of your PostgreSQL servers (e.g., `IPS=("172.17.17.242" "172.17.17.243")`).
   - `DB_NAMES`: Add the names of the databases to back up (e.g., `DB_NAMES=("netbox" "other_db")`).
6. Save the file by pressing `Ctrl+O`, then `Enter`, and exit with `Ctrl+X`.

#### Make the Script Executable
1. Make the script executable:
   ```bash
   chmod +x backup_postgres.sh
   ```

### 4. Set Up PostgreSQL Access
The script uses the `netbox` user to connect to the PostgreSQL databases. Ensure the user has access.

1. Verify that the `netbox` user can connect to each database:
   ```bash
   psql -U netbox -h 172.17.17.242 -p 5432 -d netbox
   ```
   Replace `172.17.17.242` and `netbox` with your IP and database name. If prompted, enter the password.
2. If you get a connection error, check with your database administrator to:
   - Ensure the `netbox` user exists and has the correct permissions.
   - Confirm the PostgreSQL server allows connections from your server (check `pg_hba.conf`).
3. To avoid password prompts, create a `.pgpass` file for automatic authentication:
   ```bash
   echo "172.17.17.242:5432:netbox:netbox:your_password" > ~/.pgpass
   chmod 600 ~/.pgpass
   ```
   Replace `your_password` with the actual password for the `netbox` user. Add more lines for other IPs/databases if needed.

### 5. Test the Script
1. Run the script manually to test it:
   ```bash
   ./backup_postgres.sh
   ```
2. Check the backup files in `/netbox-backup/backups`:
   ```bash
   ls /netbox-backup/backups
   ```
   You should see files like `backedup_netbox_172.17.17.242_2025-04-23.sql`.
3. Check the log file for details:
   ```bash
   cat /var/log/pg_dump.log
   ```
   Look for messages like `[2025-04-23 12:34:56] ✅ Backup successful...` or `[2025-04-23 12:34:56] ❌ Backup failed...`.
4. Check your Google Chat space for a notification. It should look like:
   ```
   Backup Summary (2025-04-23 12:34:56):
   ✅ Successfully Backuped for database 'netbox' at IP '172.17.17.242': /netbox-backup/backups/backedup_netbox_172.17.17.242_2025-04-23.sql
   ```

### 6. Schedule the Script (Optional)
To run the script automatically (e.g., daily), use `cron`.

1. Open the cron editor:
   ```bash
   crontab -e
   ```
2. Add a line to run the script daily at 2 AM (adjust the time as needed):
   ```bash
   0 2 * * * /path/to/backup_postgres.sh
   ```
   Replace `/path/to/backup_postgres.sh` with the full path to your script (e.g., `/home/user/backup_postgres.sh`).
3. Save and exit. The script will now run automatically.

### 7. Troubleshooting
- **No backup files created**:
  - Check the log file (`/var/log/pg_dump.log`) for errors.
  - Ensure the `netbox` user can connect to the database (see Step 4).
- **No Google Chat notifications**:
  - Verify the `WEBHOOK_URL` is correct and the Google Chat space is accessible.
  - Test the webhook manually:
    ```bash
    curl -X POST -H 'Content-Type: application/json' -d '{"text": "Test message"}' your_webhook_url
    ```
- **Permission errors**:
  - Ensure the user running the script has write access to `/netbox-backup/backups` and `/var/log/pg_dump.log`.
  - Run:
    ```bash
    sudo chown your_username /netbox-backup/backups /var/log/pg_dump.log
    sudo chmod 755 /netbox-backup/backups
    sudo chmod 644 /var/log/pg_dump.log
    ```
    Replace `your_username` with your Linux username.

### 8. Customizing the Script
- **Add more databases or servers**:
  - Edit the `IPS` and `DB_NAMES` arrays in the script to include additional IP addresses or database names.
- **Change backup retention**:
  - Modify the `find` command’s `-mtime +7` to keep backups for a different number of days (e.g., `-mtime +14` for 14 days).
- **Change backup location**:
  - Update `BACKUP_DIR` to a different folder (e.g., `/backups`).

## Notes
- The script assumes the PostgreSQL server uses port `5432`. If your server uses a different port, update the `-p 5432` in the `pg_dump` command.
- Backup files are named like `backedup_<database>_<IP>_<date>.sql` (e.g., `backedup_netbox_172.17.17.242_2025-04-23.sql`).
- The script deletes old backups matching `backedup_*_*.sql` (non-empty files older than 7 days). Empty backups are kept to avoid accidental deletion.

## Need Help?
If you run into issues or have questions, contact your system administrator or database administrator. You can also check the log file (`/var/log/pg_dump.log`) for detailed error messages.

Happy backing up!