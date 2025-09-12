# Node Exporter Installation on Multiple VM's at once using Ansible

This Ansible playbook automates the installation and configuration of Node Exporter across multiple VMs listed in your inventory file.

## Prerequisites

Before running the playbook, ensure you have:

1. Three essential files in the `files` directory:
   - `node_exporter.crt` - SSL certificate
   - `node_exporter.key` - SSL private key
   - `node_exporter-1.9.1.linux-amd64.tar.gz` (Download from [Prometheus downloads page](https://prometheus.io/download/))

2. The certificate and key files should be self-signed certificates from your Prometheus installation.

3. Proper SSH access configured from your Ansible control node to all target VMs.

## Inventory Configuration

Configure your `inventory.ini` file with target hosts in the following format:

```
172.17.17.242 ansible_port=7000 ansible_user=master
[additional hosts...]
```

Each host entry should specify:
- IP address
- SSH port (via `ansible_port`)
- SSH user (via `ansible_user`)

## Running the Playbook

Execute the playbook with the following command:

```bash
ansible-playbook -i inventory.ini node_exporter_install.yml
```

## What This Playbook Does

1. Installs Node Exporter (version 1.9.1 for Linux AMD64) on all target VMs
2. Configures SSL using the provided certificate and key
3. Sets up Node Exporter as a system service
4. Ensures the service is enabled and running

## Notes

- Make sure your Ansible control node has SSH public key authentication configured for all target VMs
- The playbook assumes you're using self-signed certificates for Node Exporter
- Adjust the Node Exporter version in the playbook if you need a different version.yml`