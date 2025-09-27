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
├── ansible.cfg
├── ansible.log
├── group_vars
│   ├── all.yaml
│   ├── dev.yaml
│   ├── prod.yaml
│   └── staging.yaml
├── inventory
│   ├── host.example
│   └── hosts.yaml
├── logs
├── playbook.yaml
├── proxmox-token-create.md
├── readme.md
├── roles
│   ├── create_vm_template
│   │   └── tasks
│   │       └── main.yaml
│   ├── download_template_image
│   │   └── tasks
│   │       └── main.yaml
│   └── setup_terraform_user
│       └── tasks
│           └── main.yaml
├── run_me.py
└── terraform_token_token_output.json
```

## 🔐 Creating a Proxmox API Token for Ansible

Refer to This [Doc](./proxmox-token-create.md)

---

## 🗂️ Inventory Configuration (`inventory/hosts.yml`)

This YAML file defines the Proxmox host and necessary variables. Adjust these variables for your environments
```bash
          ansible_host: <proxmox_host_IP>
          ansible_user: root
          ansible_ssh_private_key_file: <path/to/your_ssh_private_key>  #make sure your public key is attracted to proxmox hosts authorized_keys
      vars:
        env_name: dev
        proxmox_node: <proxmox_node_name>
        proxmox_api_host: <proxmox_host_IP>
        proxmox_api_port: <porxmox_host_port>
        ansible_api_token_secret: <token_from_upper_steps>
        vm_templates:
          - name: ubuntu-cloudimage-template
            os: ubuntu
            image_url: <link_to_the_img/iso>     #https://cloud-images.ubuntu.com/releases/plucky/release/ubuntu-25.04-server-cloudimg-amd64.img
            image_name: <name_of_the_img/iso_which_is_dowmlaoded>   #ubuntu-25.04-server-cloudimg-amd64.img
            vmid: <vm_id> #900000
            disk_size: <desired_disk_size>   #10G
            cores: "{{ common_vm_settings.cores }}"
            memory: "{{ common_vm_settings.memory }}"
            net0: "{{ common_vm_settings.net0 }}"
            storage: "{{ proxmox.storage }}"
            cloudinit: "{{ common_vm_settings.cloudinit }}"
```

**Note**: Replace placeholders like `your.proxmox.host` and `/path/to/your/private/key` with your actual Proxmox server details and SSH private key path.

---

## 🛠️ Common Variables Configuration (`group_vars/all.yaml`)

This YAML file holds all the common configs of the `create_vm_template` role. Adjust according to you needs.

```yaml
proxmox:
  storage: <your_ansible_storage_name>  #"local-lvm"
  bridge: "vmbr0"
ansible_api_user: <ansible_user_from_upper_steps>  #"ansible@pam"
ansible_api_token_id: <ansible_token_id_from_upper_stage>  #"ansible_token"
proxmox_api_role: PVEVMAdmin
terraform_user: terraform
terraform_realm: pam
terraform_role: TerraformRole
terraform_token_name: terraform_token
terraform_privs: "VM.Allocate VM.Config.CDROM VM.Config.CPU VM.Config.Disk VM.Config.Memory VM.Config.Network VM.Config.Options VM.Console VM.PowerMgmt VM.Monitor"  #these roles are nessesary to operate ansible
common_vm_settings:
  cores: 2 #modify if needed
  memory: 2048 #modify if needed
  net0: virtio,bridge=vmbr0
  cloudinit: true
```
---

## 🚀 Running the Playbook

To execute the playbook:

```bash
python3 run_me.py dev #dev means dev environments can be passed stage, qa, prod argument here but make sure to have the respective yaml in `group_vars` dir
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