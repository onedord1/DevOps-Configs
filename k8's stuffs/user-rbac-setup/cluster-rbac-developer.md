

# Kubernetes Developer Kubeconfig Setup

This guide provides step-by-step instructions to create a restricted kubeconfig file for developers, allowing them to access only selected namespaces and view pod logs.

## Purpose

To create a kubeconfig file for developers with the following restrictions:
- Access only to specified namespaces
- Only able to list pods and view pod logs
- No permissions to create, modify, or delete resources
- Optionally able to list all namespaces (but not access them)

## Prerequisites

- Access to a Kubernetes cluster with admin permissions
- kubectl installed and configured
- Basic understanding of Kubernetes RBAC

## Step-by-Step Guide

### Step 1: Create a ServiceAccount

Create a ServiceAccount in the default namespace:

```bash
kubectl create serviceaccount developer-sa -n default
```

### Step 2: Create a Secret for the ServiceAccount

In Kubernetes 1.24+, secrets are no longer automatically created for ServiceAccounts:

```bash
kubectl apply -f - << EOF
apiVersion: v1
kind: Secret
metadata:
  name: developer-sa-token
  namespace: default
  annotations:
    kubernetes.io/service-account.name: developer-sa
type: kubernetes.io/service-account-token
EOF
```

### Step 3: Create a Role for Pod Access

Create a Role that allows listing pods and viewing logs:

```yaml
# Save this as developer-role.yml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer-log-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["list", "get"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list"]
```

Apply this Role to each namespace the developer should access:

```bash
kubectl apply -f developer-role.yml -n namespace1
kubectl apply -f developer-role.yml -n namespace2
kubectl apply -f developer-role.yml -n namespace3
kubectl apply -f developer-role.yml -n namespace4
```

Replace `namespace1`, `namespace2`, etc. with your actual namespace names.

### Step 4: Create RoleBindings

Create RoleBindings to link the Role to the ServiceAccount in each namespace:

```yaml
# Save this as developer-rolebinding.yml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-log-reader-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: developer-log-reader
subjects:
- kind: ServiceAccount
  name: developer-sa
  namespace: default
```

Apply this RoleBinding to each namespace:

```bash
kubectl apply -f developer-rolebinding.yml -n namespace1
kubectl apply -f developer-rolebinding.yml -n namespace2
kubectl apply -f developer-rolebinding.yml -n namespace3
kubectl apply -f developer-rolebinding.yml -n namespace4
```

### Step 5: (Optional) Allow Listing Namespaces

If you want the developer to be able to list all namespaces:

```yaml
# Save this as developer-namespace-lister-clusterrole.yml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: developer-namespace-lister
rules:
- apiGroups: [""]
  resources: ["namespaces"]
  verbs: ["list", "get"]
```

Apply the ClusterRole:

```bash
kubectl apply -f developer-namespace-lister-clusterrole.yml
```

Create the ClusterRoleBinding:

```yaml
# Save this as developer-namespace-lister-binding.yml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: developer-namespace-lister-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: developer-namespace-lister
subjects:
- kind: ServiceAccount
  name: developer-sa
  namespace: default
```

Apply the ClusterRoleBinding:

```bash
kubectl apply -f developer-namespace-lister-binding.yml
```

### Step 6: Generate the Kubeconfig File

Extract the token and create the kubeconfig file:

```bash
# Set variables
SERVICE_ACCOUNT_NAME=developer-sa
NAMESPACE=default
CONTEXT=$(kubectl config current-context)
NEW_CONTEXT=developer-context
KUBECONFIG_FILE="developer-kubeconfig"

# Get the token
TOKEN=$(kubectl get secret developer-sa-token -n ${NAMESPACE} -o jsonpath='{.data.token}' | base64 -d)

# Get cluster information
CLUSTER_NAME=$(kubectl config get-contexts ${CONTEXT} --no-headers | awk '{print $3}')
CLUSTER_SERVER=$(kubectl config view --raw -o jsonpath="{.clusters[?(@.name==\"${CLUSTER_NAME}\")].cluster.server}")
CLUSTER_CA=$(kubectl config view --raw -o jsonpath="{.clusters[?(@.name==\"${CLUSTER_NAME}\")].cluster.certificate-authority-data}")

# Create the kubeconfig file
cat > ${KUBECONFIG_FILE} << EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: ${CLUSTER_CA}
    server: ${CLUSTER_SERVER}
  name: ${CLUSTER_NAME}
contexts:
- context:
    cluster: ${CLUSTER_NAME}
    namespace: default
    user: developer-sa
  name: ${NEW_CONTEXT}
current-context: ${NEW_CONTEXT}
users:
- name: developer-sa
  user:
    token: ${TOKEN}
EOF
```

### Step 7: Create Multiple Contexts for Easier Namespace Switching (Optional)

To make it easier to switch between namespaces, create a kubeconfig file with multiple contexts:

```bash
# Create a new kubeconfig file with multiple contexts
cat > ${KUBECONFIG_FILE} << EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: ${CLUSTER_CA}
    server: ${CLUSTER_SERVER}
  name: ${CLUSTER_NAME}
contexts:
- context:
    cluster: ${CLUSTER_NAME}
    namespace: namespace1
    user: developer-sa
  name: developer-context-namespace1
- context:
    cluster: ${CLUSTER_NAME}
    namespace: namespace2
    user: developer-sa
  name: developer-context-namespace2
- context:
    cluster: ${CLUSTER_NAME}
    namespace: namespace3
    user: developer-sa
  name: developer-context-namespace3
- context:
    cluster: ${CLUSTER_NAME}
    namespace: namespace4
    user: developer-sa
  name: developer-context-namespace4
current-context: developer-context-namespace1
users:
- name: developer-sa
  user:
    token: ${TOKEN}
EOF
```

Replace `namespace1`, `namespace2`, etc. with your actual namespace names.

## Verification

### Verify RBAC Permissions

Check if the ServiceAccount has the correct permissions:

```bash
# Check if the user can list pods in each namespace
kubectl auth can-i list pods --as=system:serviceaccount:default:developer-sa -n namespace1
kubectl auth can-i list pods --as=system:serviceaccount:default:developer-sa -n namespace2
kubectl auth can-i list pods --as=system:serviceaccount:default:developer-sa -n namespace3
kubectl auth can-i list pods --as=system:serviceaccount:default:developer-sa -n namespace4

# Check if the user can get pod logs
kubectl auth can-i get pods/log --as=system:serviceaccount:default:developer-sa -n namespace1

# Check if the user can list namespaces (if you granted this permission)
kubectl auth can-i list namespaces --as=system:serviceaccount:default:developer-sa

# Check all permissions the user has
kubectl auth can-i --list --as=system:serviceaccount:default:developer-sa
```

### Test the Kubeconfig File

Test the kubeconfig file to ensure it works correctly:

```bash
# List namespaces (if you granted this permission)
kubectl --kubeconfig=developer-kubeconfig get ns

# List pods in allowed namespaces
kubectl --kubeconfig=developer-kubeconfig get pods -n namespace1
kubectl --kubeconfig=developer-kubeconfig get pods -n namespace2
kubectl --kubeconfig=developer-kubeconfig get pods -n namespace3
kubectl --kubeconfig=developer-kubeconfig get pods -n namespace4

# View logs for a pod
POD_NAME=$(kubectl --kubeconfig=developer-kubeconfig get pods -n namespace1 -o jsonpath='{.items[0].metadata.name}')
if [ ! -z "$POD_NAME" ]; then
  echo "Testing logs for pod: $POD_NAME"
  kubectl --kubeconfig=developer-kubeconfig logs $POD_NAME -n namespace1
fi

# Test that other actions are forbidden
kubectl --kubeconfig=developer-kubeconfig create deployment test --image=nginx -n namespace1
```

## How to Use the Kubeconfig File

### Method 1: Use the Kubeconfig File Explicitly

```bash
# Use the kubeconfig file with the --kubeconfig flag
kubectl --kubeconfig=developer-kubeconfig get pods -n namespace1
kubectl --kubeconfig=developer-kubeconfig logs <pod-name> -n namespace1
```

### Method 2: Use KUBECONFIG Environment Variable

```bash
# Set the environment variable for your current session
export KUBECONFIG=developer-kubeconfig

# Now you can run commands without the --kubeconfig flag
kubectl get pods -n namespace1
kubectl logs <pod-name> -n namespace1

# When done, unset the environment variable
unset KUBECONFIG
```

### Method 3: Switch Between Contexts (if you created multiple contexts)

```bash
# Use the kubeconfig file
export KUBECONFIG=developer-kubeconfig

# List available contexts
kubectl config get-contexts

# Switch to a different namespace context
kubectl config use-context developer-context-namespace2

# Now you're in namespace2 by default
kubectl get pods
```

## Troubleshooting

### Error: "unable to load root certificates: unable to parse bytes as PEM block"

This error occurs when the certificate authority data in the kubeconfig file is incorrect. To fix this:

1. Try extracting the CA certificate directly from the cluster:
```bash
kubectl get configmap kube-root-ca.crt -n kube-system -o jsonpath='{.data.ca\.crt}' > ca.crt
CA_CERT_BASE64=$(base64 -w 0 ca.crt)
```

2. Then recreate the kubeconfig file using the `CA_CERT_BASE64` variable.

### Error: "pods is forbidden: User cannot list resource 'pods'"

This error occurs when the ServiceAccount doesn't have the correct permissions. To fix this:

1. Check if the Role exists in the namespace:
```bash
kubectl get role developer-log-reader -n namespace1
```

2. Check if the RoleBinding exists in the namespace:
```bash
kubectl get rolebinding developer-log-reader-binding -n namespace1
```

3. Verify the Role has the correct permissions:
```bash
kubectl get role developer-log-reader -n namespace1 -o yaml
```

4. If needed, update the Role with the correct permissions.

### Error: "namespaces is forbidden: User cannot list resource 'namespaces'"

This error occurs when the ServiceAccount doesn't have permission to list namespaces. To fix this:

1. If you want to allow listing namespaces, create the ClusterRole and ClusterRoleBinding as described in Step 5.
2. If you don't want to allow listing namespaces, instruct the developer to use the full namespace name in their commands.

## Security Considerations

1. **Principle of Least Privilege**: This setup follows the principle of least privilege by only granting the permissions needed to view pod logs.

2. **Token Security**: The kubeconfig file contains a token that grants access to your cluster. Store it securely and only share it with authorized developers.

3. **Namespace Isolation**: Developers can only access the namespaces you explicitly grant them access to.

4. **Regular Rotation**: Consider regularly rotating the ServiceAccount tokens for enhanced security.

5. **Audit Logging**: Enable audit logging to track actions performed with the developer kubeconfig.

## Complete YAML Files

### developer-role.yml
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer-log-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["list", "get"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list"]
```

### developer-rolebinding.yml
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-log-reader-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: developer-log-reader
subjects:
- kind: ServiceAccount
  name: developer-sa
  namespace: default
```

### developer-namespace-lister-clusterrole.yml (Optional)
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: developer-namespace-lister
rules:
- apiGroups: [""]
  resources: ["namespaces"]
  verbs: ["list", "get"]
```

### developer-namespace-lister-binding.yml (Optional)
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: developer-namespace-lister-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: developer-namespace-lister
subjects:
- kind: ServiceAccount
  name: developer-sa
  namespace: default
```