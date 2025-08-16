proxmox_target_node_name        = "proxmox"
proxmox_api_url                 = "https://10.10.10.10:8006/api2/json"
proxmox_api_token_id            = "terraform@pve!terraform-token"
proxmox_api_token_secret        = "SAMPLE_TOKEN_REPLACE_ME"

# Common Configuration
your_public_key                 = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD"

# Master VMs
master_vms_count                = 3
master_vmid_series              = 2000
master_vms_name                 = "master-node"
master_vms_description          = "K8s master node created by Terraform"
master_vms_os_type              = "cloud-init"
master_vms_os_template_name     = "k8s-master-template"
master_vms_cpu_core             = 2
master_vms_cpu_architecture     = "host"
master_vms_memory               = 2048
master_vms_scsi_controller_model= "virtio-scsi-single"
master_vms_storage_name         = "local-lvm"
master_vms_storage_size         = 32
master_vms_network_bridge       = "vmbr0"
master_vms_network_model        = "virtio"
master_ips                      = ["172.17.17.3", "172.17.17.4", "172.17.17.5"]
master_vms_username             = "terraform"
master_vms_password             = "CHANGE_ME_SECURE"

# Worker VMs
worker_vms_count                = 2
worker_vmid_series              = 3000
worker_vms_name                 = "worker-node"
worker_vms_description          = "K8s worker node created by Terraform"
worker_vms_os_type              = "cloud-init"
worker_vms_os_template_name     = "k8s-worker-template"
worker_vms_cpu_core             = 2
worker_vms_cpu_architecture     = "host"
worker_vms_memory               = 2048
worker_vms_scsi_controller_model= "virtio-scsi-single"
worker_vms_storage_name         = "local-lvm"
worker_vms_storage_size         = 32
worker_vms_network_bridge       = "vmbr0"
worker_vms_network_model        = "virtio"
worker_vms_ips                  = ["172.17.17.6", "172.17.17.7"]
worker_vms_username             = "terraform"
worker_vms_password             = "CHANGE_ME_SECURE"
