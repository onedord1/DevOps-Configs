#!/bin/bash
WEBHOOK_URL="https://chat.googleapis.com/v1/spaces/AAQAYiAD2sU/messages?key=ASyDd0ZtySjMm-fRq3CPsHI&token=fjcFGOyuZlMMa1Ms1onfCVQivpMSQ"
DATE=$(LC_TIME=en_US.UTF-8 date +%d-%b-%Y)
TAG="backup"
DROPLET_IDS=$(doctl compute droplet list --tag-name "$TAG" | awk 'NR>1 {print $1}')

echo Droplets to be backed up: $DROPLET_IDS 

for id in $DROPLET_IDS; do

  NAME=$(doctl compute droplet get "$id" --format Name --no-header)
  echo "id=$id ($NAME) is tagged with $TAG"

  BACKUP_NAME="${NAME}-${DATE}"

  STATUS=$(doctl compute droplet-action snapshot $id  --snapshot-name $BACKUP_NAME --wait  --format Status  --no-header)
  
  if [ "$STATUS" == "completed" ]; then
    echo DIGITALOCEAN droplet backup done for $NAME as $BACKUP_NAME
    MESSAGE=" DIGITALOCEAN droplet backup done Successfully ✅\nDump Date: \`$(date +"%Y-%m-%d")\`\nDroplet: `$NAME` \nBACKUP-NAME: `$BACKUP_NAME`"
    curl -X POST -H "Content-Type: application/json" -d "{\"text\": \"$MESSAGE\"}" "$WEBHOOK_URL"

  else    
    echo DIGITALOCEAN droplet backup unsuccessful for $NAME as $BACKUP_NAME 
    MESSAGE="❌❌❌\nDIGITALOCEAN droplet backup unsuccessful on $(date +"%Y-%m-%d")\nDroplet: `$NAME`"
    curl -X POST -H "Content-Type: application/json" -d "{\"text\": \"$MESSAGE\"}" "$WEBHOOK_URL"
  fi

done
