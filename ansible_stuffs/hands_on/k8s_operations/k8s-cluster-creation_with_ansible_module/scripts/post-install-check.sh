#!/bin/bash

set -e

echo "Running post-installation checks..."

# Check if kubeconfig exists
if [ ! -f "./files/kubeconfig/config" ]; then
    echo "Error: Kubeconfig not found at ./files/kubeconfig/config"
    exit 1
fi

export KUBECONFIG="./files/kubeconfig/config"

# Check all nodes are Ready
echo "Checking node status..."
NOT_READY_NODES=$(kubectl get nodes --no-headers | grep -v "Ready" | wc -l)
if [ $NOT_READY_NODES -gt 0 ]; then
    echo "Error: $NOT_READY_NODES nodes are not ready"
    kubectl get nodes
    exit 1
fi

# Check all system pods are running
echo "Checking system pods..."
NOT_RUNNING_PODS=$(kubectl get pods -n kube-system --no-headers | grep -v "Running" | wc -l)
if [ $NOT_RUNNING_PODS -gt 0 ]; then
    echo "Warning: $NOT_RUNNING_PODS system pods are not running"
    kubectl get pods -n kube-system
fi

# Check CoreDNS is working
echo "Testing CoreDNS..."
kubectl run -it --rm --restart=Never busybox --image=busybox:1.28 -- sh -c 'nslookup kubernetes.default' > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: CoreDNS is not working properly"
    exit 1
fi

# Check Calico is working
echo "Checking Calico network..."
CALICO_PODS=$(kubectl get pods -n kube-system -l k8s-app=calico-node --no-headers | wc -l)
if [ $CALICO_PODS -eq 0 ]; then
    echo "Error: No Calico pods found"
    exit 1
fi

# Check MetalLB is working
echo "Checking MetalLB..."
METALLB_PODS=$(kubectl get pods -n metallb-system --no-headers | wc -l)
if [ $METALLB_PODS -eq 0 ]; then
    echo "Error: No MetalLB pods found"
    exit 1
fi

# Test pod-to-pod communication
echo "Testing pod-to-pod communication..."
kubectl run -it --rm --restart=Never test-pod-1 --image=busybox:1.28 -- sh -c 'sleep 30' &
kubectl run -it --rm --restart=Never test-pod-2 --image=busybox:1.28 -- sh -c "ping -c 3 test-pod-1" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: Pod-to-pod communication is not working"
    exit 1
fi

# Test LoadBalancer service
echo "Testing LoadBalancer service..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: test-lb
spec:
  selector:
    app: test
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: LoadBalancer
EOF

sleep 10
LB_IP=$(kubectl get svc test-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ -z "$LB_IP" ]; then
    echo "Error: LoadBalancer IP not assigned"
    kubectl delete svc test-lb
    exit 1
fi

kubectl delete svc test-lb

echo "All post-installation checks passed successfully!"