
# Ultimate Github Actions Workflow with Deployment

## Overview
This guide details the end-to-end process for building, tagging, and pushing Docker images to AWS ECR (Elastic Container Registry) from GitHub Actions, deploying these images to a Kubernetes cluster via ArgoCD.

### Workflow Summary:
1. **GitHub Actions**: On push, the workflow builds, tags, and pushes Docker images to ECR.
2. **AWS CLI & Docker Setup**: AWS CLI and Docker are set up and logged in to ECR.
3. **Image Tagging**: Docker images are tagged using a build number or SHA.
4. **Deployment Update**: A Kubernetes manifest file is updated with the new image tag.
5. **ArgoCD**: ArgoCD synchronizes and deploys updates to the Kubernetes cluster, with pods pulling the image from ECR via a secret.

---

## Prerequisites

- AWS account with permissions for ECR and EC2.
- GitHub repository with configured Actions workflows.
- Kubernetes cluster with ArgoCD installed.

---

## Phase 1: Local Docker Image Push to ECR

### 1. Set Up AWS CLI
Install AWS CLI V2:
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```
Verify with:
```bash
aws --version
```

### 2. Configure IAM for ECR Access
In the AWS Console:
1. Go to **IAM > Users**.
2. Attach the `AmazonEC2ContainerRegistryFullAccess` policy to a new or existing user.
3. Generate Access Key ID and Secret Access Key for login.

### 3. Configure AWS Credentials Locally
Run:
```bash
aws configure
```
Provide your Access Key ID, Secret Access Key, and region.

### 4. Push Docker Image to ECR
1. **Login to ECR**:
   ```bash
   aws ecr get-login-password --region <your-region> | docker login --username AWS --password-stdin <account-id>.dkr.ecr.<your-region>.amazonaws.com
   ```
2. **Tag and Push Image**:
   ```bash
   docker tag <your-image-name>:latest <account-id>.dkr.ecr.<your-region>.amazonaws.com/<your-repo-name>:latest
   docker push <account-id>.dkr.ecr.<your-region>.amazonaws.com/<your-repo-name>:latest
   ```

---

## Phase 2: Automation with GitHub Actions and Kubernetes Deployment

### Step 1: EC2 Instance Setup
1. SSH into your EC2 instance:
   ```bash
   ssh -i <your_pem_file> ubuntu@<instance_public_ip>
   ```
2. Install Docker and AWS CLI:
   ```bash
   sudo apt-get update
   sudo apt-get install -y docker.io awscli
   ```
3. Add the Docker user to the `docker` group:
   ```bash
   sudo usermod -aG docker $USER
   ```

### Step 2: Configure GitHub Self-Hosted Runner
1. Go to **GitHub Repository > Settings > Actions > Runners**.
2. Add a new self-hosted runner with the required configuration.
3. All commands and instructions provide by github on that pages should be done in EC2 instances
4. Start the runner on the EC2 instance with:
   ```bash
   ./run.sh
   ```

### Step 3: Create GitHub Actions Workflow File

Add this to your workflow file:
```yaml
runs-on: ['self-hosted', 'Linux', 'X64']
```
you will see the changes below demo script yml where to changes


# ArgoCD Steps[Optional]

### Step 4: Install ArgoCD on Kubernetes
1. Create the ArgoCD namespace and install ArgoCD:
   ```bash
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```

2. **Access ArgoCD**:
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```
   Open [http://localhost:8080](http://localhost:8080), default username: `admin`.

3. **Obtain Initial Password**:
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode
   ```

### Step 5: Configure the ArgoCD Application
1. Use the CLI:
   ```bash
   argocd app create <APP_NAME>        --repo <REPO_URL>        --path <MANIFEST_PATH>        --dest-server https://kubernetes.default.svc        --dest-namespace <NAMESPACE>
   ```

### Step 6: Set Up ECR Image Pull Secrets for Kubernetes
1. Add the `imagePullSecrets` field in your Kubernetes manifest:
   ```yaml
   spec:
     containers:
     - name: <container-name>
       image: <your-image>
     imagePullSecrets:
       - name: ecr-secret
   ```
2. Create the secret in your cluster:
   ```bash
   kubectl create secret docker-registry ecr-secret --docker-server=699475925713.dkr.ecr.ap-south-1.amazonaws.com --docker-username=AWS --docker-password=$(aws ecr get-login-password --region ap-south-1) --docker-email=test.com
   ```

---


3. Demo yaml script >>> to run the script yaml config must inside `.github/github_actions`

```

name: Goal-app-build-ECR-image-deploy

on:
  push:
    branches:
      - main
  pull_request:
    <!-- types: 
      -closed --> ##commented
    branches:
      - main

jobs:
  <!-- if_merged:
   if: github.event.pull_request.merged == true --> ##commented
   build:
      runs-on: ubuntu-latest 
      #runs-on: ['self-hosted', 'Linux', 'X64'] (if you wish to run your self-hosted machine like EC2 or any other VMs)

      steps:
         - name: Checkout code
         uses: actions/checkout@v3

         - name: Set up Docker Buildx
         uses: docker/setup-buildx-action@v2

         - name: Log in to Amazon ECR
         env:
            AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
            AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
            AWS_REGION: ${{ secrets.AWS_REGION }}
            AWS_ACCOUNT_ID: ${{ secrets.AWS_ACCOUNT_ID }}
            GH_PAT: ${{ secrets.GH_PAT }}
         run: |
            aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.$AWS_REGION.amazonaws.com

         - name: Set Docker image tag
         id: vars
         run: echo "IMAGE_TAG=latest-${{ github.sha }}" >> $GITHUB_ENV

         - name: Build Docker Image
         run: |
            docker build -t ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.${{ secrets.AWS_REGION }}.amazonaws.com/goal-app-frontend:${{ env.IMAGE_TAG }} .

         # Push the Docker image to Amazon ECR
         - name: Push Docker Image
         run: |
            docker push ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.${{ secrets.AWS_REGION }}.amazonaws.com/goal-app-frontend:${{ env.IMAGE_TAG }}

         # Update the Kubernetes deployment YAML with the new image tag
         - name: Update Kubernetes Deployment YAML
         run: |
            cat ./argocd_deployment/deployment.yaml
            sed -i "s|image: .*goal-app-frontend:.*|image: ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.${{ secrets.AWS_REGION }}.amazonaws.com/goal-app-frontend:${{ env.IMAGE_TAG }}|g" ./argocd_deployment/deployment.yaml
            cat ./argocd_deployment/deployment.yaml
         # Commit the updated YAML file back to the repository
         - name: Commit updated Kubernetes YAML
         run: |
            git config --local user.name "Abir-K"
            git config --local user.email "abirbeatz@gmail.com"
            git add ./argocd_deployment/deployment.yaml
            git commit -m "Update image tag to ${{ env.IMAGE_TAG }}"
            git push https://${{ secrets.GH_PAT }}@github.com/Abir-K/goal-frontend-with-jenkins
```

## Troubleshooting
1. **Permissions**: Ensure your IAM user has `AmazonEC2ContainerRegistryFullAccess`.
2. **GitHub Runner**: Confirm the runner is active and linked in GitHub.
3. **Kubernetes Pull Error**: Verify that `imagePullSecrets` is correctly configured in the Kubernetes manifest.
4. **Repository Permissions**: Ensure your WorkFlow permission is set to `Read and write permissions` from **Repository Settings>Actions>General**.
