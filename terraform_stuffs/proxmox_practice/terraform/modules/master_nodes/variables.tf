variable "master_vms_count" {
  description = "Number of master VMs to create"
  type        = number
  default     = 1
}

variable "master_vmid_series" {
  description = "Base VM ID series In The ProxMox"
  type        = number
  default     = 2000
}

variable "master_ips" {

  description = "list of master vm ip's"
  type        = list(string)
  default     = ["172.17.17.3","172.17.17.19","172.17.17.54"]
  #array length should be equal to the number of master count
  validation {
    condition     = length(var.master_ips) >= var.master_vms_count
    error_message = "The length of master_ips must be greater/equal to master_vm_count."
  }
}

variable "master_vms_cpu_core" {
  description = "Number of cpu cores of the master vms"
  type        = number
  default     = 2
}

variable "master_vms_memory" {
  description = "memory in (MB) of the master vms"
  type        = number
  default     = 2000
}

variable "master_vms_os_template_name" {
  description = "template of the cloud init server to be cloned"
  type        = string
}

variable "proxmox_target_node_name" {
  description = "target node name of your proxmox server"
  type        = string
  default     = "proxmox"
}

variable "master_vms_storage_name" {
  description = "name of the storage in the node"
  type        = string
  default     = "local-lvm"
}

variable "master_vms_storage_size" {
  description = "size of the storage in GB !should be exact same as declared in the cloud init image creation process!"
  type        = number
}

variable "master_vms_username" {
  description = "common username of the server"
  type        = string
  default     = ""
  sensitive   = true
}
variable "master_vms_password" {
  description = "common password of the server"
  type        = string
  default     = ""
  sensitive   = true
}
variable "your_public_key" {
  description = "public key of your machine, at ~/.ssh/id_rsa.pub "
  type        = string
  default     = ""
  sensitive   = true
}

variable "master_vms_name" {
  description = "name of the vm"
  type = string
  default = "proxmox"
}

variable "master_vms_description" {
  type = string
  default = "this is master virtual machine created by terraform"
}

variable "master_vms_os_type" {
  type = string
  default = "cloud-init"
  description = "os_type for the server vm"
}

variable "master_vms_cpu_architecture" {
  type = string
  default = "host"
  description = "cpu architecture for the vms"
}

variable "master_vms_scsi_controller_model" {
  description = "The model of the SCSI controller for the virtual machine. Common choices include 'virtio-scsi-single' for a single virtio SCSI controller, 'lsi' for an LSI Logic parallel SCSI controller, and 'megaraid' for an LSI MegaRAID SAS controller. This affects the VM's disk performance and compatibility."
  type        = string
  default     = "virtio-scsi-single"

  validation {
    condition     = contains(["virtio-scsi-single", "lsi", "megaraid", "pvscsi"], var.master_vms_scsi_controller_model)
    error_message = "The SCSI controller model must be one of 'virtio-scsi-single', 'lsi', 'megaraid', or 'pvscsi'."
  }
}

variable "master_vms_network_bridge" {
  description = "The network bridge to which the VM's network interface will connect"
  type        = string
  default     = "vmbr0"
}

variable "master_vms_network_model" {
  description = "The network model for the VM's network interface. Common values include 'virtio', 'e1000', and 'vmxnet3'"
  type        = string
  default     = "virtio"

  validation {
    condition     = contains(["virtio", "e1000", "vmxnet3"], var.master_vms_network_model)
    error_message = "The network model must be one of 'virtio', 'e1000', or 'vmxnet3'."
  }
}
