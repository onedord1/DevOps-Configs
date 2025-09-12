import os
from pydo import Client
import requests
from datetime import datetime, timedelta, timezone

webhook_url=os.getenv("webhook_url")
do_token=os.getenv("do_token")
TAG="backup"
body = {"type": "snapshot"}
client = Client(token=do_token) 
now = datetime.now(timezone.utc)
threshold = now - timedelta(days=4)

def main():
    snapshots = client.snapshots.list(resource_type="droplet",per_page=100)["snapshots"]
    for snapshot in snapshots:
        created_at = datetime.fromisoformat(snapshot["created_at"].replace("Z", "+00:00"))
        is_older_than_4_days = created_at < threshold
        if is_older_than_4_days == True:
            print(f"Snapshot '{snapshot['name']}' created at {created_at} -> Older than 4 days where now {now} ? {is_older_than_4_days}")
            try:
                resp = client.snapshots.delete(snapshot_id=snapshot["id"])
                print(f"✅ Snapshot deleted successfully of: {snapshot['name']}")
                # send successful msg to google chat
                message = (
                    f"✅"
                    f"DO droplet backup bot\n"
                    f"✅ Snapshot deleted successfully of: {snapshot['name']}\n"
                    )
                payload = {"text": message}
                response = requests.post(webhook_url, json=payload)


            except Exception as e:
                print(f"Error performing action on droplet {snapshot['name']}: {e}") 
                message = (
                    f"❌❌ERROR❌❌"
                    f"DO droplet backup bot\n"
                    f"❌ Error performing delete action on snapshot {snapshot['name']}"
                    f"{e}\n"
                    )
                payload = {"text": message}
                response = requests.post(webhook_url, json=payload)