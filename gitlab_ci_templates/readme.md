# GitLab CI Templates Documentation

This document provides comprehensive guidance on using the GitLab CI templates for Node.js projects (React, Vue, etc.). It covers branching strategies, repository variable setup, and implementation on existing codebases.

## Table of Contents

- [1. Git Branching Strategies](#1-git-branching-strategies)
  - [1.1. Prerequisites](#11-prerequisites)
  - [1.2. Branch Structure](#12-branch-structure)
  - [1.3. Merge Flow Strategy](#13-merge-flow-strategy)
  - [1.4. Pipeline Execution](#14-pipeline-execution)
  - [1.5. Custom Branch Creation](#15-custom-branch-creation)
  - [1.6. CI File Synchronization](#16-ci-file-synchronization)
- [2. Setting Up Repository Variables](#2-setting-up-repository-variables)
  - [2.1. Prerequisites](#21-prerequisites)
  - [2.2. API Command Structure](#22-api-command-structure)
  - [2.3. Example Commands](#23-example-commands)
  - [2.4. Variable Types and Options](#24-variable-types-and-options)
- [3. Setup CI/CD Processes](#3-setup-cicd-processes)
  - [3.1. Prerequisites](#31-prerequisites)
  - [3.2. File Structure Setup](#32-file-structure-setup)
  - [3.3. Configuration Steps](#33-configuration-steps)
  - [3.4. Verification](#34-verification)

---

## 1. Git Branching Strategies

This CI template is designed to work with a specific branching strategy optimized for Node.js projects (React, Vue, etc.). The strategy follows GitLab's "branch per environment" approach.

### 1.1. Prerequisites

Before implementing this branching strategy, ensure:

- You have Maintainer or Owner role for the project
- GitLab runners are available and configured
- Merge request settings are properly configured

### 1.2. Branch Structure

The template supports the following standard branches:

- **dev**: Development branch where features are integrated
- **qa**: Quality assurance branch for testing
- **prod**: Production branch for live deployments

### 1.3. Merge Flow Strategy

The ultimate merging strategy follows this flow:

**feature/* → dev → qa → prod*

**Important Configuration:**
1. Check the Merge Requests Settings of your repository
2. Ensure the **Merge method** is set to **Merge Commit** (not Fast Forward Merge)
3. This ensures proper pipeline triggers and history tracking

### 1.4. Pipeline Execution

The pipeline executes different jobs based on the merge request context:

**Feature Branch → dev Branch:**
- Automatically runs 2 jobs when merge request is just create:
  - `sonarqube`: Code quality analysis
  - `imagebuild`: Docker image creation

- After merge request review and acceptance:
  - `update manifests`: Kubernetes manifest updates
  - `trigger-argo`: ArgoCD deployment trigger

### 1.5. Custom Branch Creation

If you need additional environment branches (UAT, STAGE, etc.):

1. Create the new branch from the respective stable branch
2. Edit the `.gitlab-ci.yml` file
3. Create a new CI file with the branch name (e.g., `ci-uat.yaml`)
4. Modify the code according to your specific needs
5. Update the pipeline configuration to include the new branch

### 1.6. CI File Synchronization

**Critical Condition:** Both the feature branch and target branch must have synchronized GitLab CI files for the pipeline to run correctly. This means:

- The `.gitlab-ci.yml` file must be identical across branches
- All referenced CI files in the `.gitlab/` directory must be in sync
- Any changes to CI configuration must be merged through the proper branch flow

---

## 2. Setting Up Repository Variables

Repository variables are essential for CI/CD pipeline execution. This section explains how to set them up using the GitLab API.

### 2.1. Prerequisites

Before setting up repository variables:

- Generate a Personal Access Token with `api` scope
- Get your Project ID (available in project settings)
- Ensure you have Maintainer or Owner permissions

### 2.2. API Command Structure

Use the following curl command to create repository variables:

```bash
curl --request POST \
  --header "PRIVATE-TOKEN: <your-access-token>" \
  "https://gitlab.example.com/api/v4/projects/<project-id>/variables" \
  --form "key=<variable-name>" \
  --form "value=<variable-value>"
```

### 2.3. Example Commands

**Basic Variable Creation:**
```bash
curl --request POST \
  --header "PRIVATE-TOKEN: glpat-xxxxxxxxxxxxxxxxxxxx" \
  "https://gitlab.com/api/v4/projects/12345678/variables" \
  --form "key=DOCKER_REGISTRY" \
  --form "value=registry.gitlab.com"
```

**Variable with Additional Options:**
```bash
curl --request POST \
  --header "PRIVATE-TOKEN: glpat-xxxxxxxxxxxxxxxxxxxx" \
  "https://gitlab.com/api/v4/projects/12345678/variables" \
  --form "key=API_KEY" \
  --form "value=secret-api-key" \
  --form "masked=true" \
  --form "protected=true" \
  --form "environment_scope=production"
```

### 2.4. Variable Types and Options

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `key` | string | Yes | Variable name (A-Z, a-z, 0-9, _ only) |
| `value` | string | Yes | Variable value |
| `description` | string | No | Variable description |
| `masked` | boolean | No | Hide variable value in logs (default: false) |
| `protected` | boolean | No | Restrict to protected branches (default: false) |
| `environment_scope` | string | No | Limit to specific environments (default: *) |
| `variable_type` | string | No | Type: env_var or file (default: env_var) |

---

## 3. Setup CI/CD Processes

This section guides you through implementing the CI templates on existing codebases.

### 3.1. Prerequisites

Before setting up CI/CD:

- Node.js project (React, Vue, etc.)
- GitLab project with Maintainer/Owner access
- Available GitLab runners
- Dockerfiles in the project root (for containerization)
- Nexus configuration (if using artifact repository)

### 3.2. File Structure Setup

Your project should have the following structure:

```
project-root/
├── .gitlab-ci.yml          # Main CI configuration
├── .gitlab/                # CI template files
│   ├── ci-dev.yaml         # Development environment CI
│   ├── ci-qa.yaml          # QA environment CI
│   ├── ci-prod.yaml        # Production environment CI
│   └── ...                 # Other environment CI files
├── Dockerfile              # Container configuration
├── package.json            # Node.js dependencies
└── ...                     # Other project files
```

### 3.3. Configuration Steps

**Step 1: Copy Main CI Configuration**
```bash
# Copy .gitlab-ci.yml to project root
cp path/to/template/.gitlab-ci.yml ./
```

**Step 2: Create .gitlab Directory**
```bash
# Create .gitlab folder in root directory
mkdir .gitlab

# Copy CI template files
cp path/to/template/.gitlab/*.yaml ./.gitlab/
```

**Step 3: Modify Configuration Files**

Edit `.gitlab-ci.yml` to align with your branch names:
```yaml
include:
  - local: '.gitlab/ci-dev.yaml'
    rules:
      - if: '$CI_COMMIT_BRANCH == "dev"'
  - local: '.gitlab/ci-qa.yaml'
    rules:
      - if: '$CI_COMMIT_BRANCH == "qa"'
  - local: '.gitlab/ci-prod.yaml'
    rules:
      - if: '$CI_COMMIT_BRANCH == "prod"'
```

**Step 4: Customize Environment CI Files**

Edit each environment CI file (`.gitlab/ci-*.yaml`) according to your needs:
- Update image names and tags
- Configure environment-specific variables
- Adjust deployment parameters
- Set up proper artifact handling

**Step 5: Verify Docker Configuration**

Ensure your Dockerfile exists in the root directory and is properly configured:
```dockerfile
# Example Dockerfile for Node.js
FROM node:16-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build
EXPOSE 3000
CMD ["npm", "start"]
```
- Reference Dockerfile for Node.js applications [Dockerfile](./frontend/nodejs/Dockerfile)
- Reference Dockerfile for Springboot applications [Dockerfile](./backend/springboot/Dockerfile)

**Step 6: Nexus Configuration (if applicable)**

If using Nexus artifact repository:
- Ensure nexus configuration files are in the root directory In this case, nexus-artifacthub/settings-docker.xml
- Update repository variables with Nexus credentials
- Configure artifact upload/download in CI jobs

### 3.4. Verification

After setup, verify your CI/CD pipeline:

1. **Check Runner Availability**
   - Go to Settings → CI/CD → Runners
   - Ensure at least one runner is active (green circle)

2. **Test Pipeline**
   - Create a feature branch
   - Make a small change
   - Create a merge request to dev branch
   - Verify pipeline runs with sonarqube and imagebuild jobs

3. **Validate Merge Flow**
   - Merge feature to dev
   - Create merge request dev to qa
   - Verify pipeline runs with update manifests and trigger-argo jobs

4. **Check Environment Deployments**
   - Ensure deployments are triggered correctly
   - Verify application is accessible in each environment

---

## Troubleshooting

### Common Issues

**Pipeline Not Triggering:**
- Verify CI file synchronization between branches
- Check merge request settings (must be Merge Commit, not Fast Forward)
- Ensure runner is available and active

**Variable Not Found:**
- Verify variable was created successfully
- Check variable scope (protected/environment-specific)
- Ensure correct Project ID is used in API calls

**Docker Build Failures:**
- Verify Dockerfile exists in root directory
- Check Dockerfile syntax and dependencies
- Ensure proper registry authentication
