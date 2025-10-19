# Creating a QCOW2 Cloud-Init Template in Proxmox VE

This guide provides a step-by-step process to create a virtual machine template in Proxmox VE using the **QCOW2** disk format. Using QCOW2 on a directory-based storage allows for features like efficient snapshots, linked clones, and built-in thin provisioning.

## Table of Contents

1.  [Prerequisites](#prerequisites)
2.  [The Challenge: Why Not Use `local-lvm`?](#the-challenge-why-not-use-local-lvm)
3.  [Step 1: Create a Directory Storage](#step-1-create-a-directory-storage)
4.  [Step 2: The Automated Script](#step-2-the-automated-script)
5.  [Step 3: Script Breakdown](#step-3-script-breakdown)
6.  [Step 4: Using Your New Template](#step-4-using-your-new-template)
7.  [⚠️ CRITICAL WARNING: LVM Thin Pool Over-Provisioning](#-critical-warning-lvm-thin-pool-over-provisioning)

## Prerequisites

-   A working Proxmox VE installation.
-   A cloud-ready image file (e.g., `ubuntu-24.04-minimal-cloudimg-amd64.img`) downloaded to your Proxmox host.
-   Root or administrative access to the Proxmox shell (via SSH or the web console).

## The Challenge: Why Not Use `local-lvm`?

Proxmox's default `local-lvm` is an **LVM-thin** storage, which is a **block-level** storage. It natively uses the **RAW** format and is highly optimized for performance.

**QCOW2**, on the other hand, is a **file-based format** that offers features like internal snapshots, compression, and copy-on-write efficiency. To use QCOW2 effectively, we need a **file-level storage**.

The solution is to create a new **Directory-based storage** in Proxmox, which is perfectly suited for hosting QCOW2 disk images.

## Step 1: Create a Directory Storage

First, we need to add a new storage that can host QCOW2 files. You can do this via the Web GUI or the CLI.

### Via the Web GUI

1.  Navigate to `Datacenter -> Storage -> Add -> Directory`.
2.  Fill in the details:
    -   **ID**: `qcow2-storage`
    -   **Directory**: `/var/lib/vz/qcow2-storage` (or any other path you prefer)
    -   **Content**: Check the `Disk image` box.
3.  Click `Add`.

### Via the Command Line (CLI)

1.  Create the directory on the node's filesystem:
    ```bash
    mkdir -p /var/lib/vz/qcow2-storage
    ```

2.  Add the storage configuration to `/etc/pve/storage.cfg`:
    ```ini
    dir: qcow2-storage
        path /var/lib/vz/qcow2-storage
        content images
    ```

## Step 2: The Automated Script

This script automates the entire process: creating the VM, importing the disk, converting it to QCOW2, and turning it into a template.

1.  Create a file named `create_template.sh`.
2.  Copy and paste the following script into the file.
3.  Make the script executable: `chmod +x create_template.sh`.
4.  Run the script: `./create_template.sh`.
5.  Reference Template: [Template](./template.sh)

## Step 3: Script Breakdown

-   **Configuration**: Variables at the top make the script easy to reuse.
-   **`qm create`**: Creates a basic VM without a disk.
-   **`qm disk import`**: Imports the source image into our `qcow2-storage`. By default, this creates a RAW disk.
-   **`pvesm path`**: This is the key to a robust script. It asks Proxmox for the exact, real-world file path of the imported volume, avoiding any guesswork.
-   **`qemu-img convert`**: Converts the imported RAW file into a new QCOW2 file.
-   **`qm set`**: Attaches our newly created QCOW2 disk to the VM's `scsi0` controller and configures other settings like CloudInit and boot order.
-   **`qm template`**: Converts the VM into a template, which can be cloned.

## Step 4: Using Your New Template

Once the script finishes, you will have a ready-to-use template.

1.  **Clone the Template** to create a new VM:
    ```bash
    # qm clone <TemplateID> <NewVMID> --name <new-vm-name>
    qm clone 6666 123 --name ubuntu-vm-01
    ```

2.  **Configure the Cloned VM** (e.g., set SSH key and IP address):
    ```bash
    qm set 123 --sshkey ~/.ssh/id_rsa.pub
    qm set 123 --ipconfig0 ip=192.168.1.123/24,gw=192.168.1.1
    ```

3.  **Start the new VM**:
    ```bash
    qm start 123
    ```

## ⚠️ CRITICAL WARNING: LVM Thin Pool Over-Provisioning

During this process, you may have seen warnings like this in your logs:

```
WARNING: You have not turned on protection against thin pools running out of space.
WARNING: Sum of all thin volume sizes (3.21 TiB) exceeds the size of thin pool pve/data and the size of whole volume group (1.86 TiB).
```

**This is a serious problem that can lead to data corruption and VM crashes.**

It means you have allocated more disk space to your VMs (3.21 TiB) than the physical space available in your `local-lvm` storage (1.86 TiB). If your VMs start writing data and fill up the physical pool, all VMs on that storage will fail.

**You must address this immediately by:**

-   **Adding more physical disks** to your server and expanding the `pve` Volume Group.
-   **Deleting unnecessary VMs or disks** to free up allocated space.
-   **Carefully monitoring your storage usage** with the command `pvesm status` and avoiding further over-provisioning.

---