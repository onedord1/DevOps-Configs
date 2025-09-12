import os
from pydo import Client
from datetime import datetime
import requests

current_date = datetime.now().strftime("%Y-%m-%d")
webhook_url=os.getenv("webhook_url")
do_token=os.getenv("do_token")
client = Client(token=do_token) 
volume_ids=["adab7e3a-f606-11ef-a892-0a58ac14a197","2a2383d1-e710-11ef-8cfa-0a58ac14a35f"]

def main():
    for volume_id in volume_ids:
        snapshot_name = f"{volume_id}-{current_date}"
        req = {"name": snapshot_name}
        try:
            resp = client.volume_snapshots.create(volume_id=volume_id, body=req)
            print(f"✅ Snapshot created successfully: {snapshot_name}")
            # send successful msg to google chat
            message = (
               f"✅"
                f"DO volume backup bot\n"
                f"✅ Snapshot created successfully: {snapshot_name}\n"
                )
            payload = {"text": message}
            response = requests.post(webhook_url, json=payload)

        except Exception as e:
            print(f"❌ Unexpected error while creating snapshot for {snapshot_name}: {e}")
            # send failure msg to google chat
            message = (
            f"❌❌ERROR❌❌"
            f"DO volume backup bot\n"
            f"❌ Unexpected error while creating snapshot for {snapshot_name}: {e}"
            f"{e}\n"
            )
            payload = {"text": message}
            response = requests.post(webhook_url, json=payload)