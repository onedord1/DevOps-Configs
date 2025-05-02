# Kubernetes Cluster Installation on Ubuntu 22.04

This guide will walk you through setting up a Kubernetes Cluster on your Ubuntu machine. The steps include setting up static IP addresses, disabling swap, installing Kubernetes components, initializing the cluster, configuring the network, and deploying applications.

## Prerequisites for Installing a Kubernetes Cluster

Ensure that your Ubuntu machine meets the following requirements:

- **At least 1 Node** (for dev)
- **2 vCPUs**
- **At least 4GB of RAM**
- **At least 20GB of Disk Space**
- A **reliable internet connection**

## Overall Configuration Steps

1. Setting up the **Static IPV4** on all nodes.
2. Disabling **swap** and setting up **hostnames**.
3. Installing Kubernetes components on all nodes.
4. Initializing the **Kubernetes cluster**.
5. Configuring **kubectl**.
6. Configuring **Calico Network operator**.
7. Printing **Join token** and adding worker nodes to the cluster.
8. **Deploying Applications**.

---

## 1. Setting up Static IPV4 on All Nodes (Master & Worker Node)

First, check the DHCP IP and interface using:

```bash
ip a

Then, edit the netplan file to set a static IP address:

```bash
sudo vim /etc/netplan/01-netcfg.yaml

```

Add or modify the following configuration based on your network settings:

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens33:
      dhcp4: no
      addresses:
        - 192.168.10.245/24
      routes:
        - to: default
          via: 192.168.10.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]

```

Apply the changes:

```bash
sudo netplan apply

```

----------

## 2. Disabling Swap & Setting up Hostnames (Master & Worker Node)

Disabling swap may not be necessary for future versions, but it is recommended for now.

```bash
sudo apt-get update
sudo swapoff -a
sudo vim /etc/fstab
sudo init 6

```

Set the hostname for each node:

For Master Node:

```bash
sudo hostnamectl set-hostname "master-node"

```

For Worker Node:

```bash
sudo hostnamectl set-hostname "worker-node"

```

----------

## 3. Installing Kubernetes Components on All Nodes (Master & Worker Node)

### 3.1 Configure Kernel Modules

```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

```

Load the necessary modules:

```bash
sudo modprobe br_netfilter
sudo modprobe overlay

```

### 3.2 Configure Networking Parameters

```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

```

Apply the sysctl settings:

```bash
sudo sysctl --system

```

### 3.3 Install Containerd

```bash
sudo apt-get update
sudo apt-get install -y containerd

```

### 3.4 Modify Containerd Configuration

```bash
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

```

Restart containerd service:

```bash
sudo systemctl restart containerd.service
sudo systemctl status containerd

```

### 3.5 Install Kubernetes Management Tools

Install Kubernetes tools:

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg

```

Add Kubernetes APT repository:

```bash
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

```

Install the Kubernetes components:

```bash
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

```

----------

## 4. Initializing the Kubernetes Cluster (Master Node)

Initialize the control-plane on the master node:

```bash
sudo kubeadm init --apiserver-advertise-address=172.17.17.200 --pod-network-cidr=192.168.0.0/16 --cri-socket /run/containerd/containerd.sock --ignore-preflight-errors Swap

```

-   Replace `172.17.17.200` with your Master node IP.
-   `192.168.0.0/16` is the Pod CIDR. If you change this, update the CNI Network Configuration operator file.

----------

## 5. Configuring `kubectl` (Master Node)

Create the kubeconfig file to use `kubectl`:

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

```

----------

## 6. Install Calico Networking (Master Node)

Install Calico Network Operator for on-premises deployments:

```bash
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.0/manifests/tigera-operator.yaml

```

Download custom resources for Calico:

```bash
curl https://raw.githubusercontent.com/projectcalico/calico/v3.29.0/manifests/custom-resources.yaml -O

```

If needed, customize the `custom-resources.yaml` file and create the custom resources:

```bash
kubectl create -f custom-resources.yaml

```

----------

## 7. Joining Worker Nodes to the Cluster (Master Node)

Generate the join token:

```bash
kubeadm token create --print-join-command

```

Run the printed join command on your worker nodes.

----------

## 8. Deploying Applications into the Cluster (Master Node)

To deploy Nginx using the imperative approach:

```bash
kubectl run nginx-deployment --image=nginx --replicas=3 --port=80

```

Expose the deployment externally:

```bash
kubectl expose deployment nginx-deployment --type=LoadBalancer --name=nginx-service

```

Check the running pods and services:

```bash
kubectl get pods
kubectl get services

```

----------

## Additional Resources

-   [Kubernetes Documentation](https://kubernetes.io/docs/)
-   [Calico Documentation](https://projectcalico.docs.tigera.io/)
