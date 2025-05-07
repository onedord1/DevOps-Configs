# Velero Setup for DigitalOcean Kubernetes Cluster

This guide outlines the steps to set up Velero for backup and restore operations on a Kubernetes cluster running on DigitalOcean, using DigitalOcean Spaces for object storage.

## Prerequisites

- A Kubernetes cluster running on DigitalOcean (managed or self-hosted).
- DigitalOcean account with the following resources:
  - API personal access token.
  - Spaces access keys (access key and secret key).
  - Spaces bucket.
  - Spaces bucket region.
- Velero v1.2.0 or newer, along with its prerequisites.

## Credentials Setup

1. **DigitalOcean API Token**:
   - Create a DigitalOcean API token for use with Velero to enable persistent volume snapshots.

2. **Spaces Access Keys**:
   - Generate a Spaces access key and secret key for Velero's object storage component.

3. **Create Cloud Credentials File**:
   - Create a `cloud-credentials` file with the following format:
     ```ini
     [default]
     aws_access_key_id=<AWS_ACCESS_KEY_ID>
     aws_secret_access_key=<AWS_SECRET_ACCESS_KEY>
     ```
   - Replace `<AWS_ACCESS_KEY_ID>` and `<AWS_SECRET_ACCESS_KEY>` with your DigitalOcean Spaces access key and secret key, respectively. Remove the `<` and `>` characters.

## Velero Installation

1. **Install Velero**:
   - Use the following command to install Velero, specifying the kubeconfig file if installing on multiple clusters:
     ```bash
     velero install \
       --provider velero.io/aws \
       --bucket aes-bucket \
       --plugins velero/velero-plugin-for-aws:v1.3.0,digitalocean/velero-plugin:v1.1.0 \
       --backup-location-config s3Url=https://sgp1.digitaloceanspaces.com,region=sgp1,s3ForcePathStyle=true \
       --use-volume-snapshots=false \
       --secret-file=./cloud-creds \
       --kubeconfig=/home/master/.kube/corteza_prod.kubeconfig
     ```

## Create Backup Schedules for Multiple Clusters

1. **Schedule for First Cluster**:
   - Create a backup schedule for the `cortezado-cement-config` namespace using the specified kubeconfig:
     ```bash
     KUBECONFIG=/home/master/.kube/corteza_prod.kubeconfig velero schedule create cortezado-cement-config \
       --schedule "0 11 * * *" \
       --include-namespaces cortezado-cement-gtsx-ns \
       --ttl 72h
     ```

2. **Schedule for Second Cluster**:
   - Create a backup schedule for the `cortezado-ishpat-config` namespace using a different kubeconfig:
     ```bash
     KUBECONFIG=/home/master/.kube/cortezaail.kubeconfig velero schedule create cortezado-ishpat-config \
       --schedule "20 18 * * *" \
       --include-namespaces cortezado-ishpat-fucq-ns \
       --ttl 72h
     ```

## Verify Schedules

- Check the configured schedules for a specific cluster:
  ```bash
  KUBECONFIG=/home/master/.kube/corteza_prod.kubeconfig velero get schedule
  ```

## Edit Backup Storage Location

- Modify the default backup storage location if needed:
  ```bash
  kubectl edit backupstoragelocation default -n velero
  ```

## Notes

- Ensure the `cloud-credentials` file is securely stored and accessible to Velero.
- The `--use-volume-snapshots=false` flag disables volume snapshots; enable it if needed by setting it to `true` and ensuring the DigitalOcean API token is configured.
- Adjust the `--schedule` cron expressions and `--ttl` values as per your backup retention requirements.
- The `s3Url` and `region` in the `--backup-location-config` should match your DigitalOcean Spaces bucket details.