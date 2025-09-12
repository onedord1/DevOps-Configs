#!/bin/bash
WEBHOOK_URL="https://chat.googleapis.com/v1/spaces/AAQAYiAD2sU/messages?key=AIzaSyDdI0hCZtE6vySjMm-WEfRq3CPzqKqqsHI&token=fjcFGOyBD9uZlMMa1MfkUWEsS5C1onf3HfCVQivpMSQ"
BACKOFF=false 
# BACKUP VARIABLES
DATE=$(LC_TIME=en_US.UTF-8 date +%d-%b-%Y)
TAG="backup"

# SNAPSHOT DELETE VARIABLES
DAYS_TO_KEEP=500


###################################################
###############    BACKUP    ##################### 
###################################################
DROPLET_IDS=$(doctl compute droplet list --tag-name "$TAG" | awk 'NR>1 {print $1}')

echo Droplets to be backed up: $DROPLET_IDS 

for id in $DROPLET_IDS; do

    NAME=$(doctl compute droplet get "$id" --format Name --no-header)
    echo "id=$id ($NAME) is tagged with $TAG"

    BACKUP_NAME="${NAME}-${DATE}"

    STATUS=$(doctl compute droplet-action snapshot $id  --snapshot-name $BACKUP_NAME --wait  --format Status  --no-header)
    
    if [ "$STATUS" == "completed" ]; then
        echo DIGITALOCEAN droplet backup done for $NAME as $BACKUP_NAME
        MESSAGE=" DIGITALOCEAN droplet backup done Successfully ✅\nDATE: \`$(date +"%Y-%m-%d")\`\nDROPLET: $NAME \nBACKUP-NAME: $BACKUP_NAME"
        curl -X POST -H "Content-Type: application/json" -d "{\"text\": \"$MESSAGE\"}" "$WEBHOOK_URL"

    else    
        echo DIGITALOCEAN droplet backup unsuccessful for $NAME as $BACKUP_NAME 
        MESSAGE="❌❌❌\nDIGITALOCEAN droplet backup unsuccessful on $(date +"%Y-%m-%d")\nDROPLET: $NAME"
        curl -X POST -H "Content-Type: application/json" -d "{\"text\": \"$MESSAGE\"}" "$WEBHOOK_URL"
        BACKOFF=true
    fi

done

###################################################
###############    CLEAN    ##################### 
###################################################
if [ "$BACKOFF" = false ]; then
    echo "✅ All backups completed successfully. Proceeding with the next step..."
    SNAPSHOTS=$(doctl compute snapshot list --resource droplet --format ID,Name,CreatedAt --no-header)

    while IFS= read -r snapshot; do
        SNAPSHOT_ID=$(echo "$snapshot" | awk '{print $1}')
        SNAPSHOT_NAME=$(echo "$snapshot" | awk '{print $2}')
        CREATED_AT=$(echo "$snapshot" | awk '{print $3}')

        # Convert snapshot date to seconds
        CREATED_DATE=$(date -d "$CREATED_AT" +%s)
        CURRENT_DATE=$(date +%s)
        AGE_DAYS=$(( (CURRENT_DATE - CREATED_DATE) / 86400 ))

        if [ "$AGE_DAYS" -gt "$DAYS_TO_KEEP" ]; then
            echo "Deleting snapshot $SNAPSHOT_NAME (ID=$SNAPSHOT_ID) - $AGE_DAYS days old"
            doctl compute snapshot delete "$SNAPSHOT_ID" --force

            MESSAGE="💣💣💣💥💥💥\nDELETING DIGITALOCEAN droplet backup \nSNAPSHOT_NAME: $SNAPSHOT_NAME"
            curl -X POST -H "Content-Type: application/json" -d "{\"text\": \"$MESSAGE\"}" "$WEBHOOK_URL"
        else
            echo "Keeping snapshot $SNAPSHOT_NAME (ID=$SNAPSHOT_ID) - $AGE_DAYS days old"
        fi
    done <<< "$SNAPSHOTS"

else
    echo "Entering BACKOFF mode. Some backups failed."
    MESSAGE="☢️☢️ BAKOFF MODE ON ☢️☢️ \nSome backups failed."
    curl -X POST -H "Content-Type: application/json" -d "{\"text\": \"$MESSAGE\"}" "$WEBHOOK_URL"
fi
