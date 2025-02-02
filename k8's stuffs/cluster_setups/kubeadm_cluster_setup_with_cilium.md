# Kubernetes 1.32 Cluster Setup with Cilium CNI

![Kubernetes](https://img.shields.io/badge/Kubernetes-1.32-blue?logo=kubernetes)
![Cilium](https://img.shields.io/badge/CNI-Cilium_1.16.6-blue?logo=cilium)
![OS](https://img.shields.io/badge/OS-Ubuntu_22.04-orange)

This document details the setup of a Kubernetes 1.32 cluster using Cilium CNI with kube-proxy replacement and Hubble observability.

## 📋 Prerequisites
- Ubuntu 22.04 Node
- Static IP for control plane (`172.17.17.160` in this setup)
- Root/sudo access

```markdown
## 🛠 Setup Steps

### 1. System Configuration
```bash
# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Load kernel modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

# Configure sysctl
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
net.ipv4.conf.all.forwarding = 1
net.ipv6.conf.all.forwarding = 1
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.conf.all.rp_filter = 0
net.ipv6.conf.all.rp_filter = 0
EOF
sudo sysctl --system
```

### 2. Install Containerd
```bash
sudo apt-get update
sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd.service
```

### 3. Install Kubernetes Components
```bash
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```
# Now on, all the config should be applied on master/control-plane only

## 🚀 Cluster Initialization 
```bash
sudo kubeadm init \
  --apiserver-advertise-address=172.17.17.160 \
  --pod-network-cidr=192.168.0.0/16 \
  --node-name=control-plane \
  --skip-phases=addon/kube-proxy \
  --cri-socket /run/containerd/containerd.sock \
  --ignore-preflight-errors Swap

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

## 🌐 Cilium CNI Installation

### values.yaml Configuration
```yaml
kubeProxyReplacement: "true"
k8sServiceHost: "172.17.17.160"
k8sServicePort: 6443

hubble:
  relay:
    enabled: true

ipam:
  operator:
    clusterPoolIPv4PodCIDRList:
    - "192.168.0.0/16"
```

### Install with Helm
```bash
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm -y

helm repo add cilium https://helm.cilium.io/
helm repo update
helm upgrade -i cilium cilium/cilium \
  --version 1.16.6 \
  --namespace kube-system \
  -f values.yaml
```

## 🔗 Join Worker Nodes
```bash
# Generated join command (run on worker nodes)
kubeadm token create --print-join-command
```

## ✔️ Verification
```bash
kubectl get nodes
kubectl -n kube-system get pods
```

## 📌 Important Notes
- Control Plane IP: `172.17.17.160`
- Pod CIDR: `192.168.0.0/16`
- kube-proxy is replaced by Cilium
- Hubble observability is enabled
- Cluster uses containerd runtime with systemd cgroup driver
