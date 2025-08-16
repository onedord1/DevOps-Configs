output "master_vms_count" {
  description = "The number of master VMs created"
  value       = var.master_vms_count
}

output "master_node_details" {
  description = "Complete details of all created master nodes including VM ID, name, IP address, and target node"
  value = {
    for i, vm in proxmox_vm_qemu.master_nodes : "${vm.name}-${i+1}" => {
      vm_id       = vm.vmid
      name        = "${vm.name}-${i+1}"
      ip_address  = element(var.master_ips, i)
      target_node = vm.target_node
      cpu_cores   = vm.cores
      cpu_arch    = vm.cpu
      memory_mb   = vm.memory
      storage     = var.master_vms_storage_name
      storage_size = var.master_vms_storage_size
      description = vm.desc
      os_type     = vm.os_type
      network_bridge = var.master_vms_network_bridge
      network_model  = var.master_vms_network_model
      scsihw      = vm.scsihw
    }
  }
}

output "master_node_vmids" {
  description = "List of VM IDs for all master nodes"
  value       = proxmox_vm_qemu.master_nodes[*].vmid
}

output "master_node_names" {
  description = "List of VM names for all master nodes (with index appended for uniqueness)"
  value       = [for i, vm in proxmox_vm_qemu.master_nodes : "${vm.name}-${i+1}"]
}

output "master_node_ips" {
  description = "List of IP addresses for all master nodes"
  value       = var.master_ips
}

output "master_node_ssh_connections" {
  description = "SSH connection commands for all master nodes"
  value = [
    for i, ip in var.master_ips : 
    "ssh ${var.master_vms_username}@${ip}"
  ]
}

output "master_node_inventory" {
  description = "Ansible-style inventory format for master nodes"
  value = {
    master_nodes = {
      hosts = {
        for i, vm in proxmox_vm_qemu.master_nodes : "${vm.name}-${i+1}" => {
          ansible_host = element(var.master_ips, i)
          ansible_user = var.master_vms_username
          vm_id        = vm.vmid
          target_node  = vm.target_node
          cpu_cores    = vm.cores
          cpu_arch     = vm.cpu
          memory_mb    = vm.memory
          os_type      = vm.os_type
        }
      }
    }
  }
}

output "master_node_summary" {
  description = "Summary table of master nodes with key information"
  value = formatlist(
    "%s | ID: %d | IP: %s | Node: %s | CPU: %d cores (%s) | RAM: %d MB",
    [for i, vm in proxmox_vm_qemu.master_nodes : "${vm.name}-${i+1}"],
    proxmox_vm_qemu.master_nodes[*].vmid,
    var.master_ips,
    proxmox_vm_qemu.master_nodes[*].target_node,
    proxmox_vm_qemu.master_nodes[*].cores,
    proxmox_vm_qemu.master_nodes[*].cpu,
    proxmox_vm_qemu.master_nodes[*].memory
  )
}

output "master_node_access_info" {
  description = "Formatted access information for all master nodes"
  value = [
    for i, vm in proxmox_vm_qemu.master_nodes : {
      node_name = "${vm.name}-${i+1}"
      vm_id     = vm.vmid
      ip        = element(var.master_ips, i)
      ssh       = "ssh ${var.master_vms_username}@${element(var.master_ips, i)}"
      console   = "https://${vm.target_node}:8006/#v1:0:${vm.target_node}/qemu/${vm.vmid}"
    }
  ]
}