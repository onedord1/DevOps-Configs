# re-init
```
kubeadm init \
  --apiserver-advertise-address=<your-internal-ip> \
  --apiserver-cert-extra-sans=115.127.101.126 \
  --pod-network-cidr=192.168.0.0/16

```
Verify:
```
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout
```
# OR............................
# Update existing cluster
* . cd to the pki directory
`cd /etc/kubernetes/pki`
* . Verify:
```
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout
```

### 1. Generate a New Certificate with the Additional SANs
1. `vi kubernetes-csr.conf`
2.  **Create a configuration file for the CSR (e.g., `kubernetes-csr.conf`)**:
```
[ req ]
default_bits       = 2048
prompt             = no
default_md         = sha256
req_extensions     = req_ext
distinguished_name = dn

[ dn ]
CN = kubernetes

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster.local
IP.1 = 10.96.0.1
IP.2 = 172.17.18.161
IP.3 = 115.127.101.126  # Add your public IP here

```
* . **Backup the original certificates**
```
sudo cp /etc/kubernetes/pki/apiserver.crt /etc/kubernetes/pki/apiserver.crt.bak
sudo cp /etc/kubernetes/pki/apiserver.key /etc/kubernetes/pki/apiserver.key.bak
```

### 2. **Generate the private key and CSR**:
```
sudo openssl genrsa -out /etc/kubernetes/pki/apiserver.key 2048
sudo openssl req -new -key /etc/kubernetes/pki/apiserver.key -out /etc/kubernetes/pki/apiserver.csr -config kubernetes-csr.conf
```
### 3.  **Sign the CSR with your Kubernetes CA**:

Assuming you have access to your Kubernetes CA files (`ca.crt` and `ca.key`):

```
sudo openssl x509 -req -in /etc/kubernetes/pki/apiserver.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out /etc/kubernetes/pki/apiserver.crt -days 365 -extensions req_ext -extfile kubernetes-csr.conf
```

### 4. Restart the Kubernetes API Server

1.  **Restart the kube-apiserver pod**:

If your control plane components are running as static pods (common in kubeadm setups), you can restart the `kube-apiserver` pod by removing the current pod. The kubelet will automatically recreate it using the updated certificates.

`kubectl delete pod -n kube-system -l component=kube-apiserver`

### Verify:
```
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout
```

