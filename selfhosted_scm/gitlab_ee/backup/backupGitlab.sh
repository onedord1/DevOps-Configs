#!/bin/bash
export PATH=$PATH:$HOME/minio-binaries/
CONTAINER_NAME="gitlab-main-server"
WEBHOOK_URL="https://chat.googleapis.com/v1/spaces/AAAA9obFQb4/messages?key=AIzaSyDdI0hCZtE6vySjMm-WEfRq3CPzqKqqsHI&token=k3wepCe6vlfFVvS4qBf-9ATMIw0QgtXXOOlt7wwVRks"

echo "------Starting GitLab backup inside Docker container: $CONTAINER_NAME------"

if docker exec -t "$CONTAINER_NAME" gitlab-backup create; then
    echo "✅ GitLab backup completed successfully."
    MESSAGE="GitLab Dump Created Successfully ✅"
    curl -X POST -H "Content-Type: application/json" -d "{\"text\": \"$MESSAGE\"}" "$WEBHOOK_URL"
else
    echo "❌ Failed to create GitLab backup. Checking container status..."
    MESSAGE="❌ GitLab Dump Failed"
    curl -X POST -H "Content-Type: application/json" -d "{\"text\": \"$MESSAGE\"}" "$WEBHOOK_URL"
    exit 1
fi

sleep 1

latest_backup=$(basename "$(ls -t /var/www/gitlab/backups/*.tar | head -n 1)")

echo "------Latest backup file: $latest_backup------"
echo "------copying files to minio server------"

if mc cp /var/www/gitlab/backups/$latest_backup minio-local/gitlab-backup-storage/; then 
    echo "✅ Successfully copied GitLab backup files to MinIO server."
    MESSAGE="GitLab Backup Files Copied Successfully to MinIO ✅"
    curl -X POST -H "Content-Type: application/json" -d "{\"text\": \"$MESSAGE\"}" "$WEBHOOK_URL"
else
    echo "❌ Failed to copy GitLab backup files..."
    MESSAGE="❌ Failed to copy GitLab backup files to MinIO"
    curl -X POST -H "Content-Type: application/json" -d "{\"text\": \"$MESSAGE\"}" "$WEBHOOK_URL"
    exit 1
fi

# Keep only the last 3 backups
echo "------Cleaning up old backups from local machine, keeping only the latest 3------"
ls -1t /var/www/gitlab/backups/*.tar | tail -n +4 | xargs -r rm -f

echo "------Cleaning up old backups from minio, keeping only the latest 3------"
mc ls minio-local/gitlab-backup-storage --rewind 3d --recursive --json | jq -r '.key' | while read -r object; do mc rm minio-local/gitlab-backup-storage/$object  ; done

echo "✅ Cleanup complete."