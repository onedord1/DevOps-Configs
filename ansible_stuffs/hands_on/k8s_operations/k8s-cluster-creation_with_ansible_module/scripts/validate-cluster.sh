#!/bin/bash

set -e

echo "Validating Kubernetes cluster..."

# Check if kubeconfig exists
if [ ! -f "./files/kubeconfig/config" ]; then
    echo "Error: Kubeconfig not found at ./files/kubeconfig/config"
    exit 1
fi

export KUBECONFIG="./files/kubeconfig/config"

# Check cluster connectivity
echo "Checking cluster connectivity..."
kubectl cluster-info

# Check node status
echo "Checking node status..."
kubectl get nodes -o wide

# Check system pods
echo "Checking system pods..."
kubectl get pods -n kube-system

# Check CoreDNS
echo "Checking CoreDNS..."
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Check Calico
echo "Checking Calico..."
kubectl get pods -n kube-system -l k8s-app=calico-node

# Check MetalLB
echo "Checking MetalLB..."
kubectl get pods -n metallb-system

# Check cluster components
echo "Checking cluster components..."
kubectl get cs

# Test pod deployment
echo "Testing pod deployment..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  labels:
    app: test
spec:
  containers:
  - name: nginx
    image: nginx:1.21
    ports:
    - containerPort: 80
EOF

# Wait for test pod to be ready
echo "Waiting for test pod to be ready..."
kubectl wait --for=condition=ready pod/test-pod --timeout=60s

# Test service
echo "Testing service..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: test-service
spec:
  selector:
    app: test
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: LoadBalancer
EOF

# Wait for LoadBalancer IP
echo "Waiting for LoadBalancer IP..."
sleep 10
kubectl get svc test-service

# Cleanup test resources
echo "Cleaning up test resources..."
kubectl delete pod test-pod
kubectl delete svc test-service

echo "Cluster validation completed successfully!"