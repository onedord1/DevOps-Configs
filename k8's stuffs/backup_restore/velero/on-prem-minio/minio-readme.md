# Velero with MinIO Setup Guide

This guide outlines the steps to set up Velero with MinIO for Kubernetes cluster backups, including troubleshooting common issues and scheduling backups.

## Prerequisites

1. **Kubernetes Management Host**:
   - Ensure access to a bastion host or machine with `kubectl` configured to interact with your Kubernetes cluster.

2. **MinIO Bucket**:
   - Create a MinIO bucket to store Velero backups.
   - Obtain the following credentials:
     - **MinIO Access Key ID**
     - **MinIO Secret Access Key**

3. **Cloud Credentials File**:
   - Create a file named `cloud-credentials` with the following content:
     ```ini
     [default]
     aws_access_key_id=<MINIO_ACCESS_KEY_ID>
     aws_secret_access_key=<MINIO_SECRET_ACCESS_KEY>
     ```
   - Replace `<MINIO_ACCESS_KEY_ID>` and `<MINIO_SECRET_ACCESS_KEY>` with your actual MinIO credentials, removing the `<` and `>` characters.

## Installing Velero

Use the following command to install Velero with MinIO as the backup storage provider. Ensure you have the correct `kubeconfig` file.

```bash
velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:v1.3.0 \
  --bucket prod-cluser-allconfigs-velero \
  --secret-file ./local-creds \
  --use-volume-snapshots=false \
  --backup-location-config region=ap-south-1,s3ForcePathStyle="true",s3Url=https://bucket.cloudaes.com \
  --kubeconfig=/home/master/.kube/local_prod.kubeconfig
```

## Troubleshooting

### Self-Signed Certificate Issue

If you encounter the following error due to a self-signed certificate:

```
tls: failed to verify certificate: x509: certificate relies on legacy Common Name field, use SANs instead
```

1. **Edit Velero Deployment**:
   - Add a `hostAliases` entry to the Velero deployment if using `/etc/hosts` configuration:
     ```yaml
     hostAliases:
     - hostnames:
       - bucket.cloudaes.com
       ip: 172.17.19.252
     ```
   - Apply the changes using `kubectl edit deployment velero -n velero`.

2. **Skip TLS Verification**:
   - If you see the following error in Velero pod logs:
     ```
     BackupStorageLocation "default" is unavailable: rpc error: code = Unknown
     ```
   - Edit the `backupstoragelocation` resource:
     ```bash
     kubectl edit backupstoragelocation default -n velero
     ```
   - Add the following under `spec.config`:
     ```yaml
     insecureSkipTLSVerify: "true"
     ```
   - Save and exit, then check the Velero pod logs to confirm the issue is resolved.

### NGINX Configuration for MinIO

If using NGINX to route the MinIO client, ensure the following configuration to avoid upload issues:

```nginx
client_max_body_size 100M;
```

Add this to the NGINX configuration to allow larger file uploads.

## Scheduling Backups

Schedule regular backups using the following command:

```bash
KUBECONFIG=/home/master/.kube/local_prod.kubeconfig velero schedule create local-prod-cluster-allconfigs \
  --schedule "40 18 * * *" \
  --exclude-resources=persistentvolumes,persistentvolumeclaims \
  --include-namespaces=* \
  --snapshot-volumes=false \
  --ttl 72h
```

### Explanation of Options:
- **`--schedule "40 18 * * *"`**: Runs the backup daily at 18:40 (6:40 PM).
- **`--exclude-resources`**: Excludes `persistentvolumes` and `persistentvolumeclaims` from the backup.
- **`--include-namespaces=*`**: Includes all namespaces in the backup.
- **`--snapshot-volumes=false`**: Disables volume snapshots.
- **`--ttl 72h`**: Backups expire after 72 hours.

## Notes
- Ensure the `kubeconfig` path is correct for your environment.
- Verify MinIO bucket accessibility before running the Velero installation.
- Regularly check Velero pod logs for any issues after configuration changes.