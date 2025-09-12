# this script gets all the volume from sgp region and snapshots them
from datetime import datetime
from pydo import Client
import requests

region = "sgp1"
client = Client(token="dop_v1_3b92703fd0a4fbfbf65fb2b1c85bc230b") 
current_date = datetime.now().strftime("%Y-%m-%d")
webhook_url="https://chat.googleapis.com/v1/spaces/AAQAYiAD2sU/messages?key=AIzaSyDdI0E6vySjMm-WEzqKqqsHI&token=fjcFGOyBD9uZlMMfkovpMSQ"
def snapshot_volumes():
    try:
        volumes = client.volumes.list(region=region)["volumes"]
    except Exception as e:
        # send msg to google chat
        message = (
            f"❌❌ERROR❌❌"
            f"DO volume backup bot\n"
            f"{e}\n"
        )
        payload = {"text": message}
        response = requests.post(webhook_url, json=payload)
        return

    for volume in volumes:
        volume_name = volume["name"]
        snapshot_name = f"{volume_name}-{current_date}"
        req = {
            "name": snapshot_name
        }

        try:
            resp = client.volume_snapshots.create(volume_id=volume["id"], body=req)
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
            print(f"❌ Unexpected error while creating snapshot for {volume_name}: {e}")
            # send failure msg to google chat
            message = (
            f"❌❌ERROR❌❌"
            f"DO volume backup bot\n"
            f"❌ Unexpected error while creating snapshot for {volume_name}: {e}"
            f"{e}\n"
            )
            payload = {"text": message}
            response = requests.post(webhook_url, json=payload)


snapshot_volumes()
