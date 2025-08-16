#provider_variables
variable "proxmox_api_url" {
  description = "proxmox_api_url"
  type        = string
  default = "https://10.10.10.10:8006/api2/json"

}

variable "proxmox_api_token_id" {
  description = "proxmox_api_token_id"
  type = string
  default = "terraform@pve!terraform-token"
}

variable "proxmox_api_token_secret" {
  type = string
  default = "2d091999-9cfe-41a1-8018-853a5ad1de2d" #sample_token_values
}

#master_modules_variables
variable "master_vms_count" {
  description = "Number of master VMs to create"
  type        = number
}
variable "proxmox_target_node_name" {
  description = "target node name of your proxmox server"
  type        = string
}
variable "master_vmid_series" {
  description = "Base VM ID series In The ProxMox"
  type        = number
}
variable "master_vms_name" {
  description = "name of the vm"
  type = string
}
variable "master_vms_description" {
  type = string
  default = "description for master vms"
}
variable "master_vms_os_type" {
  type = string
}
variable "master_vms_os_template_name" {
  description = "template of the cloud init server to be cloned"
  type        = string
}
variable "master_vms_cpu_core" {
  description = "Number of cpu cores of the master vms"
  type        = number
}
variable "master_vms_cpu_architecture" {
  type = string
}
variable "master_vms_memory" {
  type = number
  description = "memory size of the master vms"
}
variable "master_vms_scsi_controller_model" {
  type = string
  default = "virtio-scsi-single"
}
variable "master_vms_storage_name" {
  type = string
  default = "local-lvm"
}
variable "master_vms_storage_size" {
  type = number
  description = "size should same as template"
}
variable "master_vms_network_bridge" {
  type = string
  default = "vmbr0"
}
variable "master_vms_network_model" {
  type = string
}
variable "master_ips" {
  type = list(string)
  description = "List of IP addresses for master nodes"
}
variable "master_vms_username" {
  type = string
}
variable "master_vms_password" {
  type = string
}
variable "your_public_key" {
  type = string
  default = ""
}

#worker_module_variables
variable "worker_vms_count" {
  description = "Number of worker VMs to create"
  type        = number
}
variable "proxmox_target_node_name" {
  description = "target node name of your proxmox server"
  type        = string
}
variable "worker_vmid_series" {
  description = "Base VM ID series In The ProxMox"
  type        = number
}
variable "worker_vms_name" {
  description = "name of the vm"
  type = string
}
variable "worker_vms_description" {
  type = string
  default = "description for worker vms"
}
variable "worker_vms_os_type" {
  type = string
}
variable "worker_vms_os_template_name" {
  description = "template of the cloud init server to be cloned"
  type        = string
}
variable "worker_vms_cpu_core" {
  description = "Number of cpu cores of the worker vms"
  type        = number
}
variable "worker_vms_cpu_architecture" {
  type = string
}
variable "worker_vms_memory" {
  type = number
  description = "memory size of the worker vms"
}
variable "worker_vms_scsi_controller_model" {
  type = string
  default = "virtio-scsi-single"
}
variable "worker_vms_storage_name" {
  type = string
  default = "local-lvm"
}
variable "worker_vms_storage_size" {
  type = number
  description = "size should same as template"
}
variable "worker_vms_network_bridge" {
  type = string
  default = "vmbr0"
}
variable "worker_vms_network_model" {
  type = string
}
variable "worker_vms_ips" {
  type = list(string)
  description = "List of IP addresses for master nodes"
}
variable "worker_vms_username" {
  type = string
}
variable "worker_vms_password" {
  type = string
}
