# QuickOps Deployment Manual

This guide will help you deploy the **full QuickOps stack**, including:

- Frontend(vue)
- Backend(spring.b.)
- Database(mysql8)
- Mail Server(spring.b.)
- CloudHub (Go)

The stack will be exposed publicly with an SSL certificate configured for your domain.

---

## Prerequisites

Ensure the following are set up before you begin:

- A running **Kubernetes cluster**
- **ArgoCD** installed with UI access
- **Helm** installed on your CLI
- Access to **Harbor registry** and a **bot account** to pull and push images

---


# QuickOps Deployment - Stage 1 (manifest updates)

1. Navigate to the `k8s` directory:
   ```bash
   cd k8s
   ```

2. Update the namespace name as needed.
    ```bash
    0-ns.yaml
    ```

3. Replace all occurrences of the old namespace (e.g., `qa-quickops`) with the new one (e.g., `dev-quickops`).  
   - Use the search and replace feature in your code editor to update both namespace definitions and references.

4. Generate Harbor credentials using the bot account:

   ```bash
   echo '{"auths":{"<REGISTRY_URL>":{"username":"<USERNAME>","password":"<PASSWORD>"}}}' > dockerconfig.json
   ```

   Then base64 encode the credentials:

   ```bash
   cat dockerconfig.json | base64 -w 0
   ```

5. Copy the output and place it in the `0-secret.yaml` file under:

   ```yaml
   data:
     .dockerconfigjson: <paste_base64_data_here>
   ```

6. Push the updated code to your repository.

---



# QuickOps Deployment - Stage 2 (ArgoCD Setup)

## Steps

1. Navigate to the `argocd` directory:
   ```bash
   cd argocd
   ```

2. Open `application.yaml` and update the following:
   - **Namespace**: Match the namespace you configured in Stage 1.
   - **Repository URL**: Set this to the Git URL of your repository (in our case, the same repository containing your `k8s` manifests).
   - **Path**: Update the path to point to the Kubernetes manifests directory (e.g., `./k8s/`).

3. From the ArgoCD UI:
   - Go to **Settings** > **Repositories**
   - Connect to the Git repository specified in `application.yaml`

4. Push the updated code to your Git repository.

---

# QuickOps Deployment - Stage 3 (DNS and SSL Setup)

---

## Steps

1. Navigate to the `k8s` directory:
   ```bash
   cd k8s
   ```

2. Edit `8-certificate.yaml`:
   - Replace the domain name with your intended subdomain(s), such as `test.quickops.io`, `testbe.quickops.io`, and `testgo.quickops.io`.

3. Update your DNS provider with the following A records:
   - `test.quickops.io` → Public IP of the exposed application
   - `testbe.quickops.io` → Public IP of the exposed application
   - `testgo.quickops.io` → Public IP of the exposed application
4. Edit `9-ingress-traefik.yaml`:
    -   update the domains

4. Push the updated code to your repository.

---

# QuickOps Deployment - Stage 4 (Code Changes)

This stage involves making necessary code updates to reflect the correct domain configuration for the deployed environment.

---

## 1. Frontend Changes

- Go to the **frontend repository**
- Open the `gitlab-ci.yaml` file
- Update the build command with the correct backend subdomain:

```yaml
docker build --build-arg VITE_API_BASE_URL=https://trytbe.quickops.io --build-arg VITE_RECURRING_CALL=true -t $IMAGE_NAME:$IMAGE_TAG .
```

> Make sure the `VITE_API_BASE_URL` reflects the correct backend endpoint.

---

## 2. Backend Changes

- Go to the **backend repository**
- Navigate to:
  ```
  /src/main/java/com/aes/cloudplatform/acc/
  ```
- Open and edit the `Constants.java` file:
  - Update the domain values as follows:

```java
public static final String MULTI_CLOUD_FRONTEND_URL = "https://try.quickops.io";
public static final String MULTI_CLOUD_BACKEND_URL_FOR_WEBHOOK = "https://trybe.quickops.io";
public static final String CLOUDHUB_CREATE_CLUSTER = "https://trygo.quickops.io";
```

---


# QuickOps Deployment - Stage 5 (Apply)


---

## Steps

1. Ensure:
   - All code changes have been pushed
   - DNS records have propagated and resolved correctly

2. Apply the ArgoCD configuration:
   ```bash
   kubectl apply -f argocd/
    ```
    Navigate to the ArgoCD UI and verify the application status.

    If any application appears OutOfSync, click Sync to trigger a redeployment and resolve issues.