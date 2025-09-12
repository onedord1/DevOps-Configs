import os
from pydo import Client
import requests

webhook_url=os.getenv("webhook_url")
do_token=os.getenv("do_token")
TAG="backup"
body = {"type": "snapshot"}
client = Client(token=do_token) 

def main():
    resp = client.droplets.list(tag_name=TAG)["droplets"]
    for droplet in resp:
        try:
            resp = client.droplet_actions.post(droplet_id=droplet["id"], body=body)
            print(f"✅ Snapshot created successfully of: {droplet['name']}")
            # send successful msg to google chat
            message = (
               f"✅"
                f"DO droplet backup bot\n"
                f"✅ Snapshot created successfully of droplet: {droplet['name']}\n"
                )
            payload = {"text": message}
            response = requests.post(webhook_url, json=payload)

        except Exception as e:
            print(f"Error performing action on droplet {droplet['id']}: {e}") 
            message = (
            f"❌❌ERROR❌❌"
            f"DO droplet backup bot\n"
            f"❌ Unexpected error while creating snapshot for droplet {droplet['id']}: {e}"
            f"{e}\n"
            )
            payload = {"text": message}
            response = requests.post(webhook_url, json=payload)