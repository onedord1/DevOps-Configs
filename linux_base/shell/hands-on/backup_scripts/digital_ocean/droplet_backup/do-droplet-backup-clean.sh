#!/bin/bash
DAYS_TO_KEEP=7

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
