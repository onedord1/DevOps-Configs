Here's a cleaned-up and enhanced `README.md` based on your provided content, with added clarity, structure, and references:

---

# Velero Backup & Restore for Kubernetes Cluster on AWS

This guide explains how to install and use [Velero](https://velero.io/) to back up and restore your Kubernetes cluster. It includes setting up AWS S3 as the backup destination and configuring the necessary credentials.

## Prerequisites

1. **Access to a Kubernetes Management Host**:
   Use a bastion host or any machine with access to your Kubernetes cluster (via `kubectl`).

2. **AWS S3 Bucket**:
   Create an S3 bucket to store Velero backups. You’ll need:

   * **AWS Access Key ID**
   * **AWS Secret Access Key**

3. **IAM User Setup**:

   * Go to **IAM > Users > \[YourUser] > Security credentials**
   * Generate and download Access Key and Secret
   * These will be stored in a file named `Velero-creds`

   Example `Velero-creds` file:

   ```ini
   [default]
   aws_access_key_id=<YOUR_ACCESS_KEY_ID>
   aws_secret_access_key=<YOUR_SECRET_ACCESS_KEY>
   ```

## Installing Velero CLI

### Option 1: Homebrew (macOS)

```bash
brew install velero
```

### Option 2: Manual Installation

1. Download the release from the [official GitHub release page](https://github.com/vmware-tanzu/velero/releases/tag/v1.16.0)
2. Extract the `.tar.gz` file
3. Move the binary to your system path:

```bash
sudo mv /path/to/velero /usr/local/bin
```

> Replace `/path/to/velero` with the actual extracted path.

---

## Install Velero in the Kubernetes Cluster

```bash
velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:v1.12.0 \
  --bucket <s3_bucket_name> \
  --backup-location-config region=<aws_region> \
  --snapshot-location-config region=<aws_region> \
  --secret-file ./Velero-creds \
  --use-node-agent
```

---

## Usage

### Backup a Specific Namespace

```bash
velero backup create <backup-name> --include-namespaces <namespace>
```

### Full Cluster Backup

```bash
velero backup create full-cluster-backup \
  --all-namespaces \
  --snapshot-move-data
```

### Restore from Backup

```bash
velero restore create <restore_name> --from-backup "<backup_name>"
velero restore create demo-restore --from-backup "demo-velero-k8s"
```

### Scheduled Backups

```bash
velero schedule create <schedule_name> \
  --schedule "0 12 * * *" \
  --include-namespaces <specific_namespace> \
  --snapshot-move-data
  --ttl 48h
```

> Optional: Add `--ttl 48h` to keep the backup for 2 days.

### Check Existing Schedules

```bash
velero schedule get
```

---

## Nofication Configuration

This notifier is a simple script that will send a notification to a Webhook when a backup is only failed.

First, using that dockerfile build a docker image using the following command:

```bash
 docker build --network=host -t <yournamespace>/velero-notifier:latest .
```
Then, push the image to your Docker registry:
```bash
docker push <your_docker_registry>/velero-notifier:latest
```
By default, while installing velero, it will create a service account named `velero` in the `velero` namespace. We will use this service account to deploy the notifier.

Make sure to update the `velero-notifier` deployment with the correct image name and namespace. Just adjust timing of cron triggering and then apply the following YAML file:

```yaml
kubectl apply -f velero-notifier.yaml
```


## References

* 📚 [Velero Official Documentation – Customize Installation](https://velero.io/docs/v1.15/customize-installation/)
* 📘 [Devtron Blog – Backup and Restore Kubernetes Clusters](https://devtron.ai/blog/how-to-backup-and-restore-kubernetes-clusters/)

---
