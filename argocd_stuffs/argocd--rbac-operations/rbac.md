# ArgoCD Developer User RBAC Setup

This guide provides steps to set up RBAC for a developer user in ArgoCD.

## Prerequisites
- Kubectl installed and configured with access to the cluster
- ArgoCD installed on the cluster
- kubeconfig file with appropriate permissions

## Steps

### 1. Enable Developer Account
Edit the `argocd-cm` configmap to enable the developer account:

```bash
kubectl edit configmap argocd-cm -n argocd
```

Add the following line under `data`:
```yaml
data:
  accounts.developer: login #adjust with your desired user instead of developer
```

Save and exit.

### 2. Configure RBAC Policies
Edit the `argocd-rbac-cm` configmap to define the RBAC policies:

```bash
kubectl edit configmap argocd-rbac-cm -n argocd
```

Add the following lines under `data`, adjusting the namespace (`default/bmdsales-qa*`) as needed:

```yaml
data:
  policy.csv: |
    p, role:developer, logs, get, default/bmdsales-qa*, allow
    p, role:developer, applications, get, default/bmdsales-qa*, allow
    p, role:developer, applications, sync, default/bmdsales-qa*, allow
    g, developer, role:developer
```

Save and exit.

### 3. Install ArgoCD CLI Tool
Follow the instructions to install the ArgoCD CLI tool from the [official documentation](https://argoproj.github.io/argo-cd/cli_installation/).

For example, on Linux with curl:
```bash
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
```

### 4. Login to ArgoCD
Login to ArgoCD using the admin credentials:

```bash
argocd login <ARGOCD_SERVER> --username admin --insecure
```
Replace `<ARGOCD_SERVER>` with your ArgoCD server address (e.g., `172.17.19.12:30388`).

You will be prompted to enter the admin password.

### 5. Verify Developer Account
Check the list of accounts to verify that the developer account was added:

```bash
argocd account list
```

### 6. Set Developer Password
Update the password for the developer account:

```bash
argocd account update-password --account developer
```
You will be prompted to enter the admin password first, then you can set the developer password.

After completing these steps, the developer account should be set up with the appropriate RBAC permissions.



# ArgoCD Pod Exec Permission Setup for Admin User

This guide provides steps to enable and configure pod exec permissions for the admin user in ArgoCD.
```

Next, the prerequisites section would be similar to the previous one, but perhaps we can make it a bit more concise since the prerequisites are mostly the same.

Then, the steps:

1. Enable exec feature in ArgoCD configmap
2. Update argocd-server clusterrole
3. Update RBAC policies
4. Verification

Let's start drafting each section.

### Step 1: Enable Exec Feature

We need to edit the `argocd-cm` configmap to add the line `exec.enabled: "true"`.

### 1. Enable Exec Feature

To enable the pod exec feature in ArgoCD, you need to edit the `argocd-cm` configmap:

```bash
kubectl edit configmap argocd-cm -n argocd
```

Add the following line under `data`:

```yaml
data:
  exec.enabled: "true"
```
Save and exit the editor.

### Step 2: Update argocd-server ClusterRole

This step involves adding the required permissions to the `argocd-server` clusterrole.

### 2. Update argocd-server ClusterRole

Edit the `argocd-server` clusterrole to add permissions for pod exec:

```bash
kubectl edit clusterrole argocd-server
```

Add the following section to the `rules` array:

```yaml
- apiGroups:
  - ""
  resources:
  - pods/exec
  verbs:
  - create
```
Save and exit the editor.


### Step 3: Update RBAC Policies

Now, we need to update the RBAC policies to allow the admin role to create exec sessions.

### 3. Update RBAC Policies

Edit the `argocd-rbac-cm` configmap to update the RBAC policies:

```bash
kubectl edit configmap argocd-rbac-cm -n argocd
```

Add or update the following line in the `policy.csv` under `data`:

```yaml
data:
  policy.csv: |
    p, role:admin, exec, create, */*, allow
```
Make sure this line is present in your policy.csv. If there are existing policies, append this line to them. Save and exit the editor.


### Step 4: Verification

Finally, we need to verify that the admin can now execute into pods.


### 4. Verification

To verify that the admin user can now execute into pods:

1. Log in to the ArgoCD UI as the admin user.
2. Navigate to an application and view its pod details.
3. Check that there is an option to execute into the pod (usually available in the pod details view or via a terminal icon).


## Conclusion

After completing these steps, the admin user in ArgoCD will have the necessary permissions to execute into pods. This is useful for debugging and troubleshooting applications directly from the ArgoCD interface.
