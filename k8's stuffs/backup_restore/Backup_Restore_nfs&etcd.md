
# Backup and Restore NFS & Cluster ETCD Guide

## Phase 1: Backup NFS Data

1. SSH into the NFS server and navigate to the backup location (e.g., `/var/k8s-nfs`).
2. To back up the data, compress the backup folder using the `tar` command:
   ```bash
   tar -cvf <file/folder_name>.tar
   ```
3. Store the generated `.tar` file in a safe location for later use.

   *You can destroy the NFS server if desired, or proceed with restoration if it is already unavailable.*

## Phase 2: Backup ETCD

1. Install the `etcdctl` client on the master host machine:
   ```bash
   sudo apt-install etcd-client
   ```
2. Verify secure communication between cluster members by listing members:
   ```bash
   sudo ETCDCTL_API=3 etcdctl --endpoints <cluster_endpoints> \
     --cert=/etc/kubernetes/pki/etcd/server.crt \
     --key=/etc/kubernetes/pki/etcd/server.key \
     --cacert=/etc/kubernetes/pki/etcd/ca.crt \
     member list
   ```
3. Create a backup of the ETCD cluster:
   ```bash
   sudo ETCDCTL_API=3 etcdctl --endpoints <cluster_endpoints> \
     --cert=/etc/kubernetes/pki/etcd/server.crt \
     --key=/etc/kubernetes/pki/etcd/server.key \
     --cacert=/etc/kubernetes/pki/etcd/ca.crt \
     snapshot save backup.db
   ```
4. Verify the snapshot file:
   ```bash
   export ETCDCTL_API=3
   etcdctl --write-out=table snapshot status backup.db
   ```

## Phase 3: Restore the Cluster

1. Set up the new cluster.
2. Restore the previous ETCD snapshot:
   ```bash
   export ETCDCTL_API=3
   sudo etcdctl snapshot restore backup.db --data-dir <data-dir-location>
   ```
   Replace `<data-dir-location>` with your desired location, such as `/var/lib/etcd1`.
3. Update the cluster manifest to use the restored data directory:
   ```bash
   kubectl describe etcd-master-1 -n kube-system
   ```
4. Edit the ETCD YAML file located at `/etc/kubernetes/manifest/etcd.yaml`:
   - Update the `hostPath` to point to your restored ETCD path.

   Example:
   ```yaml
   hostPath:
     path: <your-restored-etcd-path>
   ```

## Troubleshooting
1. **NFS Networking**: Ensure your NFS IP Address is fixed and stable before backup as well as restored ETCD.
