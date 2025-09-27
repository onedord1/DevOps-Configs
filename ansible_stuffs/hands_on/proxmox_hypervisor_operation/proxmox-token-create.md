# Proxmox User and API Token Setup for Ansible

This guide will walk you through creating a Proxmox user and API token that can be used with Ansible to automate VM and template creation. This is essential for the Ansible playbook to work properly.

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Creating a Proxmox User](#creating-a-proxmox-user)
- [Creating an API Token](#creating-an-api-token)
- [Assigning Permissions](#assigning-permissions)
- [Configuring Ansible Inventory](#configuring-ansible-inventory)
- [Verifying the Setup](#verifying-the-setup)

## Overview

Proxmox uses a role-based access control system where users can be assigned specific permissions through roles. For Ansible to interact with Proxmox, we need:

1. A dedicated user account (not root)
2. An API token associated with that user
3. Appropriate permissions assigned to the user/token

This setup allows Ansible to automate tasks without using the root account, which is more secure and follows the principle of least privilege.

## Prerequisites

- Access to a Proxmox server with administrative privileges
- SSH access to the Proxmox server
- Basic familiarity with the command line

## Creating a Proxmox User

1. **SSH into your Proxmox server:**
   ```bash
   ssh root@your-proxmox-ip
   ```

2. **Create a new user for Ansible:**
   ```bash
   pveum user add ansible@pam --comment "Ansible Automation User"
   ```
   
   - `ansible@pam` creates a user named "ansible" using the PAM authentication realm
   - The `--comment` adds a descriptive note about the user

3. **Verify the user was created:**
   ```bash
   pveum user list
   ```
   
   You should see the `ansible@pam` user in the list.

## Creating an API Token

1. **Create an API token for the user:**
   ```bash
   pveum user token add ansible@pam ansible_token --privsep 0
   ```
   
   - `ansible@pam` is the user we created
   - `ansible_token` is the name of the token (you can choose any name)
   - `--privsep 0` disables privilege separation, which is needed for Ansible
   
   This command will output a UUID-like secret value. **This is the only time it will be shown**, so make sure to copy it and save it securely.

2. **Verify the token was created:**
   ```bash
   pveum user token list ansible@pam
   ```
   
   You should see the `ansible_token` in the list.

## Assigning Permissions

For Ansible to create and manage VMs and templates, the user needs appropriate permissions. We'll assign a role with the necessary permissions.

1. **Check available roles:**
   ```bash
   pveum role list
   ```
   
   You'll see various roles like `PVEVMAdmin`, `PVEAdmin`, etc.

2. **Assign the PVEVMAdmin role to the user:**
   ```bash
   pveum acl modify / --user ansible@pam --roles PVEVMAdmin
   ```
   
   This gives the user VM administration permissions across the entire Proxmox environment (`/` path).

3. **Alternatively, create a custom role with limited permissions:**
   ```bash
   pveum role add TerraformRole -privs "VM.Allocate VM.Config.CDROM VM.Config.CPU VM.Config.Disk VM.Config.Memory VM.Config.Network VM.Config.Options VM.Console VM.PowerMgmt VM.Monitor"
   pveum acl modify / --user ansible@pam --roles TerraformRole
   ```
   
   This creates a more restricted role with only the permissions needed for VM management.

## Configuring Ansible Inventory

Now that you have a user and token, update your Ansible inventory file:

```yaml
all:
  hosts:
    proxmox:
      ansible_host: your-proxmox-ip
      ansible_user: root
      ansible_ssh_private_key_file: ~/.ssh/id_ed25519
      ansible_port: 22
  vars:
    proxmox_api_user: ansible@pam
    proxmox_api_token_id: ansible_token
    proxmox_api_token_secret: your-token-secret-here
    proxmox_api_host: your-proxmox-ip
    proxmox_api_port: 8006
    proxmox_node: your-proxmox-node-name
    proxmox_api_role: PVEVMAdmin
    vm_templates:
      - name: ubuntu-cloudimage-template
        os: ubuntu
        image_url: https://cloud-images.ubuntu.com/releases/plucky/release/ubuntu-25.04-server-cloudimg-amd64.img
        image_name: ubuntu-25.04-server-cloudimg-amd64.img
        vmid: 90000
        disk_size: 10G
        cores: 2
        memory: 2048
        net0: virtio,bridge=vmbr0
        storage: local-lvm
        cloudinit: true
```

Replace:
- `your-proxmox-ip` with your Proxmox server's IP address
- `your-token-secret-here` with the secret you got when creating the token
- `your-proxmox-node-name` with your Proxmox node's name (run `pvecm nodes` to see it)

## Verifying the Setup

1. **Test the connection using curl:**
   ```bash
   curl -k -H "Authorization: PVEAPIToken=ansible@pam!ansible_token=your-token-secret-here" https://your-proxmox-ip:8006/api2/json/nodes
   ```
   
   If successful, you'll get a JSON response with node information.

2. **Run the Ansible playbook:**
   ```bash
   ansible-playbook playbook.yaml
   ```
   
   If everything is configured correctly, the playbook should run without authentication errors.