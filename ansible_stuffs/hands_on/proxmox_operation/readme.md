# Proxmox VM Template Automation with Ansible

This project automates the creation of Proxmox VM templates using Ansible, leveraging the Proxmox API for seamless integration and management.
---

## 🧰 Prerequisites

Before you begin, ensure you have the following:

* **Ansible**: Installed on your local machine.
* **Proxmox Server**: A running Proxmox instance with API access enabled.
* **Proxmox API Token**: A valid API token with appropriate permissions.
* **SSH Access**: SSH access to the Proxmox server for Ansible.([Everhour][1])

---

## 📁 Project Structure

Your project directory should resemble the following structure:

```
proxmox-vm-template-automation/
├── inventory/
│   └── hosts.yml
├── playbook.yml
└── roles/
    └── create_vm_template/
        └── tasks/
            └── main.yml
```

## 🔐 Creating a Proxmox API Token

To create an API token in Proxmox:

1. Navigate to **Datacenter > Permissions > API Tokens** in the Proxmox web interface.
2. Click **Add** and select the user (e.g., `root@pam`).
3. Provide a **Token ID** (e.g., `ansible_pve_token`).
4. Set the **Role** (e.g., `PVEVMAdmin`).
5. Click **Add** to generate the token.
6. Copy the **Token Secret** immediately; it will not be shown again.

---

## 🗂️ Inventory Configuration (`inventory/hosts.yml`)

This YAML file defines the Proxmox host and necessary variables.

```yaml
all:
  hosts:
    proxmox:
      ansible_host: your.proxmox.host
      ansible_user: root
      ansible_ssh_private_key_file: /path/to/your/private/key
  vars:
    proxmox_api_user: root@pam
    proxmox_api_token_id: ansible_pve_token
    proxmox_api_token_secret: your_api_token_secret
    proxmox_api_host: https://your.proxmox.host:8006
    proxmox_node: pve-node
    proxmox_api_role: PVEVMAdmin
    vm_templates:
      - name: ubuntu-template
        os: ubuntu
        image_url: https://cloud-images.ubuntu.com/releases/20.04/release/ubuntu-20.04-server-cloudimg-amd64.img
        image_name: ubuntu-20.04-server-cloudimg-amd64.img
        vmid: 100
        disk_size: 10G
        cores: 2
        memory: 2048
        net0: virtio,bridge=vmbr0
        storage: local-lvm
        cloudinit: true
      - name: fedora-template
        os: fedora
        image_url: https://download.fedoraproject.org/pub/fedora/linux/releases/34/Cloud/aarch64/images/Fedora-Cloud-Base-34-1.2.aarch64.qcow2
        image_name: Fedora-Cloud-Base-34-1.2.aarch64.qcow2
        vmid: 101
        disk_size: 10G
        cores: 2
        memory: 2048
        net0: virtio,bridge=vmbr0
        storage: local-lvm
        cloudinit: true
```



**Note**: Replace placeholders like `your.proxmox.host` and `/path/to/your/private/key` with your actual Proxmox server details and SSH private key path.

---

## 🛠️ Playbook Configuration (`playbook.yml`)

This YAML file orchestrates the execution of the `create_vm_template` role.

```yaml
- name: Create Proxmox VM Templates
  hosts: proxmox
  become: true
  tasks:
    - name: Include create_vm_template role
      include_role:
        name: create_vm_template
      loop: "{{ vm_templates }}"
      loop_control:
        loop_var: template
```



---

## 🧩 Role Configuration (`roles/create_vm_template/tasks/main.yml`)

This role defines the tasks to create VM templates in Proxmox.

```yaml
- name: Download cloud image
  ansible.builtin.get_url:
    url: "{{ template.image_url }}"
    dest: "/tmp/{{ template.image_name }}"
  register: download_result
  until: download_result is success
  retries: 3
  delay: 10

- name: Create VM Template
  community.general.proxmox_kvm:
    api_user: "{{ proxmox_api_user }}"
    api_token_id: "{{ proxmox_api_token_id }}"
    api_token_secret: "{{ proxmox_api_token_secret }}"
    api_host: "{{ proxmox_api_host }}"
    node: "{{ proxmox_node }}"
    vmid: "{{ template.vmid }}"
    name: "{{ template.name }}"
    cores: "{{ template.cores }}"
    memory: "{{ template.memory }}"
    net0: "{{ template.net0 }}"
    disk:
      size: "{{ template.disk_size }}"
      storage: "{{ template.storage }}"
    os: "{{ template.os }}"
    cloudinit: "{{ template.cloudinit }}"
    state: present
```

---

## 🚀 Running the Playbook

To execute the playbook:

```bash
python3 run_me.py
```

This command tells Ansible to use your specified inventory file and execute the tasks defined in `playbook.yml`.

---

## 🔐 Security Considerations

* **Avoid Hardcoding**: Do not hardcode sensitive information directly in your playbooks or inventory files.
* **Use Ansible Vault**: Encrypt sensitive variables using Ansible Vault to protect them.
* **Environment Variables**: Consider setting sensitive values as environment variables and referencing them in your playbooks.

---

## 📚 References

* [Ansible Proxmox Collection Documentation](https://docs.ansible.com/ansible/latest/collections/community/general/proxmox_inventory.html)
* [Proxmox API Documentation](https://pve.proxmox.com/pve-docs/api-viewer/)
* [FreeCodeCamp: How to Write a Good README File for Your GitHub Project](https://www.freecodecamp.org/news/how-to-write-a-good-readme-file/)

---