---

# **Reset Kubernetes Cluster** 🔄

This guide provides step-by-step instructions to **reset a Kubernetes cluster**, including removing all associated folders, `crictl`-related resources, and CNI plugins. Use this guide with caution, as it will completely wipe your cluster configuration and data.

---

## **Table of Contents** 📑

1. [Prerequisites](#prerequisites-)
2. [Steps to Reset Kubernetes Cluster](#steps-to-reset-kubernetes-cluster-)
   - [Step 1: Drain Nodes](#step-1-drain-nodes-)
   - [Step 2: Remove Pods and Containers](#step-2-remove-pods-and-containers-)
   - [Step 3: Reset Kubernetes Cluster](#step-3-reset-kubernetes-cluster-)
   - [Step 4: Clean Up Folders and Files](#step-4-clean-up-folders-and-files-)
   - [Step 5: Remove CNI Plugins](#step-5-remove-cni-plugins-)
   - [Step 6: Clean Up Container Runtime Directories](#step-6-clean-up-container-runtime-directories-)
   - [Step 7: Restart Container Runtime](#step-7-restart-container-runtime-)
3. [Verification](#verification-)

---

## **Prerequisites** 📋

- **Access to the Kubernetes cluster** with administrative privileges.
- **`kubectl`** installed and configured.
- **`crictl`** installed (if using container runtime interface).
- **Backup any important data** before proceeding, as this process is irreversible.

---

## **Steps to Reset Kubernetes Cluster** 🛠️

### **Step 1: Drain Nodes** 🚿

Drain all nodes to safely evict workloads and prepare for reset.

```bash
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
```

Replace `<node-name>` with the name of the node you want to drain. Repeat this for all nodes in the cluster.

---

### **Step 2: Remove Pods and Containers** 🗑️

Remove all running pods and containers using `crictl`.

```bash
# List all pods
sudo crictl pods

# List all containers
sudo crictl ps -a

# Remove all containers
sudo crictl rm $(sudo crictl ps -a -q)

# Remove all pods
sudo crictl rmp $(sudo crictl pods -q)
```

---

### **Step 3: Reset Kubernetes Cluster** 🔧

Use the `kubeadm reset` command to reset the cluster.

```bash
sudo kubeadm reset
```

This command will:
- Clean up the Kubernetes control plane.
- Remove all Kubernetes configuration files.

---

### **Step 4: Clean Up Folders and Files** 🧹

Manually remove all Kubernetes-related folders and files.

```bash
sudo rm -rf /etc/kubernetes
sudo rm -rf /var/lib/kubelet
sudo rm -rf /var/lib/etcd
sudo rm -rf /var/lib/cni
sudo rm -rf /etc/cni
sudo rm -rf ~/.kube
```

---

### **Step 5: Remove CNI Plugins** 🔌

Remove CNI plugins and network configurations.

```bash
sudo rm -rf /etc/cni/net.d
sudo rm -rf /opt/cni/bin
```

Restart the network interface if needed:

```bash
sudo systemctl restart networking
```

---

### **Step 6: Clean Up Container Runtime Directories** 🧽

If pods and containers still persist, clean up the container runtime’s data directories. Choose the appropriate commands based on your runtime:

#### **For containerd:**
```bash
sudo systemctl stop containerd
sudo rm -rf /var/lib/containerd
sudo systemctl start containerd
```

#### **For CRI-O:**
```bash
sudo systemctl stop crio
sudo rm -rf /var/lib/containers/
sudo systemctl start crio
```

#### **For Docker:**
```bash
sudo systemctl stop docker
sudo rm -rf /var/lib/docker
sudo systemctl start docker
```

---

### **Step 7: Restart Container Runtime** 🔄

Restart the container runtime to ensure all changes take effect.

```bash
sudo systemctl restart containerd  # or crio, or docker, depending on your runtime
```

---

## **Verification** ✅

After completing the steps, verify that all Kubernetes, `crictl`, and CNI resources have been removed.

1. Check for running containers:
   ```bash
   sudo crictl ps
   ```
   Output should be empty.

2. Check for Kubernetes processes:
   ```bash
   ps aux | grep kube
   ```
   No Kubernetes processes should be running.

3. Check for remaining files:
   ```bash
   ls /etc/kubernetes
   ls /var/lib/kubelet
   ls /etc/cni/net.d
   ls /opt/cni/bin
   ```
   These directories should not exist.

---

**Note:** This process is destructive and irreversible. Use it only when you want to completely reset your Kubernetes cluster.

---
