# Proxmox Template Creation Guide

This guide will walk you through the process of creating a template in Proxmox.

## Prerequisites
- Access to the Proxmox hypervisor server console
- SSH access to the server

## Steps to Create a Proxmox Template

1. **Access the Proxmox Hypervisor Server Console**:
   - Open your terminal.
   - SSH into your Proxmox hypervisor server.

2. **Create a Folder for the Template**:
   ```bash
   mkdir vm_template
   cd vm_template
   ```

3. **Download the Cloud Image Template**:
   - Use the following command to download the Ubuntu cloud image template:
     ```bash
     wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
     ```
   - Note: `jammy-server-cloudimg-amd64.img` is just a preference. You can adjust the image from the Ubuntu repository as per your needs.

4. **Create a Shell Script**:
   - Create a shell script named `template.sh` and add the necessary commands to it.

5. **Make the Script Executable**:
   - Use the following command to make the script executable:
     ```bash
     chmod +x template.sh
     ```

6. **Run the Script**:
   - Execute the script with the following command:
     ```bash
     ./template.sh
     ```

## Reference
- You can find the reference shell script [here](./template.sh).