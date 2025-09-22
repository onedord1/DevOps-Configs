

# Kubernetes Cluster Deployment with Ansible - Complete Guide for Beginners

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Environment Setup](#environment-setup)
3. [Configuration Overview](#configuration-overview)
4. [Step-by-Step Deployment](#step-by-step-deployment)
5. [Post-Deployment Validation](#post-deployment-validation)
6. [Common Issues & Troubleshooting](#common-issues--troubleshooting)
7. [Maintenance & Operations](#maintenance--operations)
8. [Useful Commands](#useful-commands)

---

## Prerequisites

### Hardware Requirements
- **Control Plane Nodes (Masters)**: Minimum 2 CPU, 4GB RAM, 20GB storage
- **Worker Nodes**: Minimum 2 CPU, 4GB RAM, 20GB storage
- **Network**: All nodes must be able to communicate with each other

### Software Requirements
- **Control Machine (Your Local Machine)**:
  - Ansible 2.9+ (recommended 2.11+)
  - Python 3.6+
  - SSH client
  - Git

- **Target Nodes (VMs)**:
  - Ubuntu 20.04/22.04 LTS
  - Python 3.6+
  - SSH server
  - Internet access for package downloads

### Network Requirements
- **Static IP addresses** for all nodes
- **SSH access** from control machine to all nodes
- **Open ports**: 6443 (API server), 2379-2380 (etcd), 10250 (kubelet), 10257 (scheduler), 10259 (controller-manager)

---

## Environment Setup

### Step 1: Prepare Your Control Machine
```bash
# Install Ansible on Ubuntu/Debian
sudo apt update
sudo apt install -y ansible python3-pip git

# Install required Python packages
pip3 install kubernetes openshift PyYAML

# Clone the repository (if you're using git)
git clone <your-repo-url>
cd k8s-ansible-deployment
```

### Step 2: Prepare Target Nodes
```bash
# On each target node (VM), install Python and SSH server
sudo apt update
sudo apt install -y python3 openssh-server

# Create ansible user on all nodes
sudo useradd -m -s /bin/bash ansible
sudo passwd ansible  # Set a password

# Add ansible user to sudo group
sudo usermod -aG sudo ansible

# Enable passwordless sudo for ansible user
echo "ansible ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ansible
```

### Step 3: Setup SSH Key Authentication
```bash
# On your control machine, generate SSH key if you don't have one
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

# Copy SSH key to all target nodes
for node in master1 master2 master3 worker1 worker2 worker3; do
  ssh-copy-id ansible@${node}
done

# Test SSH connection to all nodes
for node in master1 master2 master3 worker1 worker2 worker3; do
  ssh ansible@${node} "echo 'Connected to ${node}'"
done
```

### Step 4: Update Inventory Configuration
Edit `inventory/inventory.ini` with your actual node IP addresses:

```ini
[masters]
master1 ansible_host=192.168.1.10 ansible_user=ansible
master2 ansible_host=192.168.1.11 ansible_user=ansible
master3 ansible_host=192.168.1.12 ansible_user=ansible

[workers]
worker1 ansible_host=192.168.1.20 ansible_user=ansible
worker2 ansible_host=192.168.1.21 ansible_user=ansible
worker3 ansible_host=192.168.1.22 ansible_user=ansible

[cluster:children]
masters
workers

[cluster:vars]
ansible_python_interpreter=/usr/bin/python3
kubernetes_version=1.28.0
container_runtime=containerd
cni_plugin=calico
pod_network_cidr=192.168.0.0/16
service_network_cidr=10.96.0.0/12
metallb_ip_range=192.168.1.100-192.168.1.200
```

---

## Configuration Overview

### Key Configuration Files

1. **`ansible.cfg`**: Ansible configuration with optimized settings
2. **`group_vars/all/main.yml`**: Global variables for all nodes
3. **`group_vars/masters/main.yml`**: Master node specific variables
4. **`group_vars/workers/main.yml`**: Worker node specific variables

### Important Variables to Customize

In `group_vars/all/main.yml`:
```yaml
# Kubernetes version
kubernetes_version: "1.28.0"

# Network settings
pod_network_cidr: "192.168.0.0/16"
service_network_cidr: "10.96.0.0/12"

# MetalLB IP range
metallb_ip_range: "192.168.1.100-192.168.1.200"

# Resource limits (adjust based on your hardware)
kube_apiserver_cpu_requests: "1000m"
kube_apiserver_memory_requests: "2Gi"
```

In `group_vars/masters/main.yml`:
```yaml
# High availability configuration
control_plane_endpoint: "192.168.1.100"  # Virtual IP for API server

# etcd cluster configuration
etcd_initial_cluster: >
  master1=https://192.168.1.10:2380,
  master2=https://192.168.1.11:2380,
  master3=https://192.168.1.12:2380
```

---

## Step-by-Step Deployment

### Step 1: Verify Ansible Connectivity
```bash
# Test connectivity to all nodes
ansible cluster -m ping

# Check system information
ansible cluster -m setup -a "filter=ansible_distribution*"
```

### Step 2: Deploy the Complete Cluster
```bash
# Run the main playbook (this deploys everything)
ansible-playbook playbooks/setup-cluster.yml
```

### Step 3: Monitor the Deployment
```bash
# Check the progress
tail -f ansible.log

# Or run with verbose output
ansible-playbook playbooks/setup-cluster.yml -v
```

### Alternative: Step-by-Step Deployment

If you prefer to deploy components one by one:

```bash
# Step 1: Setup common components on all nodes
ansible-playbook playbooks/setup-cluster.yml --tags common

# Step 2: Initialize control plane
ansible-playbook playbooks/init-cluster.yml

# Step 3: Install CNI (Calico)
ansible-playbook playbooks/install-calico.yml

# Step 4: Configure CoreDNS
ansible-playbook playbooks/configure-coredns.yml

# Step 5: Configure etcd
ansible-playbook playbooks/configure-etcd.yml

# Step 6: Install MetalLB
ansible-playbook playbooks/install-metallb.yml

# Step 7: Join worker nodes
ansible-playbook playbooks/join-workers.yml

# Step 8: Fetch kubeconfig
ansible-playbook playbooks/fetch-kubeconfig.yml
```

---

## Post-Deployment Validation

### Step 1: Check Cluster Status
```bash
# Set kubeconfig path
export KUBECONFIG=./files/kubeconfig/config

# Check cluster information
kubectl cluster-info

# Check node status
kubectl get nodes -o wide

# Check all system pods
kubectl get pods -A
```

### Step 2: Run Validation Scripts
```bash
# Run basic cluster validation
chmod +x scripts/validate-cluster.sh
./scripts/validate-cluster.sh

# Run comprehensive post-install checks
chmod +x scripts/post-install-check.sh
./scripts/post-install-check.sh
```

### Step 3: Test Cluster Functionality
```bash
# Create a test deployment
kubectl create deployment nginx-test --image=nginx:1.21

# Expose the deployment
kubectl expose deployment nginx-test --port=80 --type=LoadBalancer

# Check the service
kubectl get svc nginx-test

# Wait for LoadBalancer IP (should be in your MetalLB range)
sleep 30
kubectl get svc nginx-test

# Test the service
curl http://<LOAD_BALANCER_IP>

# Clean up test resources
kubectl delete deployment nginx-test
kubectl delete svc nginx-test
```

### Step 4: Verify All Components
```bash
# Check CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Check Calico
kubectl get pods -n kube-system -l k8s-app=calico-node

# Check MetalLB
kubectl get pods -n metallb-system

# Check etcd (from master node)
kubectl get pods -n kube-system -l component=etcd

# Test DNS resolution
kubectl run -it --rm busybox --image=busybox:1.28 -- nslookup kubernetes.default
```

---

## Common Issues & Troubleshooting

### 1. SSH Connection Issues
```bash
# Test SSH manually
ssh ansible@master1

# If connection fails, check:
# - SSH key is properly copied
# - Firewall allows SSH (port 22)
# - Network connectivity between machines
```

### 2. Ansible Permission Issues
```bash
# Test sudo access
ssh ansible@master1 "sudo whoami"

# Should return "root", if not:
# - Check /etc/sudoers.d/ansible file
# - Verify ansible user is in sudo group
```

### 3. Package Installation Issues
```bash
# Check if repositories are accessible
ssh ansible@master1 "sudo apt update"

# If issues with Kubernetes repository:
# - Check internet connectivity
# - Verify repository URLs in group_vars
```

### 4. Kubernetes Cluster Initialization Issues
```bash
# Check kubeadm logs
ssh ansible@master1 "journalctl -u kubelet -f"

# Reset kubeadm if needed (BE CAREFUL - this destroys the cluster)
ssh ansible@master1 "sudo kubeadm reset -f"
```

### 5. Pod Not Starting Issues
```bash
# Check pod status and events
kubectl describe pod <pod-name> -n <namespace>

# Check pod logs
kubectl logs <pod-name> -n <namespace>

# Common fixes:
# - Check resource limits
# - Verify image pull access
# - Check network policies
```

### 6. Network Issues (Calico)
```bash
# Check Calico node status
kubectl get pods -n kube-system -l k8s-app=calico-node

# Check Calico BGP status
kubectl exec -it -n kube-system calico-node-xxxxxx -- calicoctl node status

# Reset Calico if needed:
kubectl delete -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml
```

### 7. MetalLB Issues
```bash
# Check MetalLB speaker logs
kubectl logs -n metallb-system -l component=speaker

# Check IP address allocation
kubectl get ipaddresspool -n metallb-system -o yaml

# Test MetalLB with a simple service
kubectl create service loadbalancer nginx --tcp=80:80
```

---

## Maintenance & Operations

### 1. Adding New Worker Nodes
```bash
# 1. Add the new node to inventory.ini
# 2. Prepare the new node (see Environment Setup)
# 3. Run worker join playbook
ansible-playbook playbooks/join-workers.yml --limit worker-new
```

### 2. Upgrading Kubernetes Version
```bash
# 1. Update kubernetes_version in group_vars/all/main.yml
# 2. Run upgrade playbook (you'll need to create this)
ansible-playbook playbooks/upgrade-cluster.yml
```

### 3. Backup and Restore
```bash
# Backup etcd data
ssh ansible@master1 "sudo etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /tmp/etcd-snapshot.db"

# Backup cluster manifests
kubectl get all -A -o yaml > cluster-backup.yaml
```

### 4. Monitoring Cluster Health
```bash
# Check node resource usage
kubectl top nodes

# Check pod resource usage
kubectl top pods -A

# Check cluster events
kubectl get events --sort-by='.metadata.creationTimestamp' -A

# Check component status
kubectl get componentstatuses
```

---

## Useful Commands

### 1. Ansible Commands
```bash
# Check inventory
ansible-inventory --list

# Run ad-hoc commands
ansible cluster -m command -a "hostname"
ansible cluster -m shell -a "free -h"

# Run with specific tags
ansible-playbook playbooks/setup-cluster.yml --tags common,init

# Dry run (check what would be changed)
ansible-playbook playbooks/setup-cluster.yml --check
```

### 2. Kubernetes Commands
```bash
# Get cluster information
kubectl cluster-info
kubectl version
kubectl get nodes

# Work with pods
kubectl get pods -A
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl exec -it <pod-name> -- /bin/bash

# Work with services
kubectl get svc -A
kubectl describe svc <service-name>

# Work with deployments
kubectl get deployments -A
kubectl scale deployment <deployment-name> --replicas=3

# Debug commands
kubectl get events --sort-by='.metadata.creationTimestamp'
kubectl get pods -o wide
kubectl get nodes -o yaml
```

### 3. System Commands (on nodes)
```bash
# Check system status
systemctl status kubelet
systemctl status containerd
systemctl status etcd

# Check logs
journalctl -u kubelet -f
journalctl -u containerd -f
journalctl -u etcd -f

# Check network
ip addr show
ip route show
netstat -tuln

# Check disk space
df -h
du -sh /var/lib/etcd
```

---