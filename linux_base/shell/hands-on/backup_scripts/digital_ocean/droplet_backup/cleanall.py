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

volume_ids=["adab7e3a-f606-11ef-a892-0a58ac14a197","2a2383d1-e710-11ef-8cfa-0a58ac14a35f"]
def clean_pvc_snaps():
    print("cleaning pvc snaps")
    for volume_id in volume_ids:
        try:
            snapshots = client.volume_snapshots.list(volume_id=volume_id)["snapshots"]
            # Sort snapshots by created_at (newest first)
            snapshots.sort(key=lambda x: x["created_at"], reverse=True)

            if len(snapshots) <= 3:
                print(f"Skipping cleanup for {volume_id} — only {len(snapshots)} snapshots found.")
                continue  # Don't delete if less than or equal to 3

            # Get the snapshots to delete (all except the latest 3)
            to_delete = snapshots[3:]

            print(to_delete)
            for snap in to_delete:
                snap_id = snap["id"]
                snap_name = snap["name"]
                try:
                    client.volume_snapshots.delete_by_id(snapshot_id=snap_id)
                    print(f"Deleted old snapshot: {snap_name}")
                    
                    # send delete info to Google Chat
                    message = (
                        f"DO volume backup bot\n"
                        f"Snapshot deleted: {snap_name}\n"
                    )
                    payload = {"text": message}
                    response = requests.post(webhook_url, json=payload)

                except Exception as e:
                    print(f"❌ Error deleting snapshot {snap_name}: {e}")
                    message = (
                        f"❌❌ERROR❌❌\n"
                        f"DO volume backup bot\n"
                        f"❌ Could not delete snapshot {snap_name}\n"
                        f"{e}"
                    )
                    payload = {"text": message}
                    response = requests.post(webhook_url, json=payload)

        except Exception as e:
            print(f"❌ Error listing snapshots for volume {volume_id}: {e}")
            message = (
                f"❌❌ERROR❌❌\n"
                f"DO volume backup bot\n"
                f"❌ Error listing snapshots for volume {volume_id}: {e}"
            )
            payload = {"text": message}
            requests.post(webhook_url, json=payload)
def clean_droplet_snaps():
    print("cleaning droplet snaps")
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

def main():
    clean_droplet_snaps()
    clean_pvc_snaps()