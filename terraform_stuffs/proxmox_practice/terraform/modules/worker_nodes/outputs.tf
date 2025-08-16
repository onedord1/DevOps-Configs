output "worker_node_details" {
  description = "Complete details of all created worker nodes including VM ID, name, IP address, and target node"
  value = {
    for vm in proxmox_vm_qemu.worker_nodes : vm.name => {
      vm_id       = vm.vmid
      name        = vm.name
      ip_address  = element(var.worker_vms_ips, count.index)
      target_node = vm.target_node
      cpu_cores   = vm.cores
      cpu_arch    = vm.cpu
      memory_mb   = vm.memory
      storage     = var.worker_vms_storage_name
      storage_size = var.worker_vms_storage_size
      description = vm.desc
      os_type     = vm.os_type
      network_bridge = var.worker_vms_network_bridge
      network_model  = var.worker_vms_network_model
      scsihw      = vm.scsihw
      username    = var.worker_vms_username
    }
  }
}

output "worker_node_vmids" {
  description = "List of VM IDs for all worker nodes"
  value       = proxmox_vm_qemu.worker_nodes[*].vmid
}

output "worker_node_names" {
  description = "List of VM names for all worker nodes"
  value       = proxmox_vm_qemu.worker_nodes[*].name
}

output "worker_node_ips" {
  description = "List of IP addresses for all worker nodes"
  value       = var.worker_vms_ips
}

output "worker_node_ssh_connections" {
  description = "SSH connection commands for all worker nodes"
  value = [
    for i, ip in var.worker_vms_ips : 
    "ssh ${var.worker_vms_username}@${ip}"
  ]
}

output "worker_node_inventory" {
  description = "Ansible-style inventory format for worker nodes"
  value = {
    worker_nodes = {
      hosts = {
        for vm in proxmox_vm_qemu.worker_nodes : vm.name => {
          ansible_host = element(var.worker_vms_ips, count.index)
          ansible_user = var.worker_vms_username
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

output "worker_node_summary" {
  description = "Summary table of worker nodes with key information"
  value = formatlist(
    "%s | ID: %d | IP: %s | Node: %s | CPU: %d cores (%s) | RAM: %d MB",
    proxmox_vm_qemu.worker_nodes[*].name,
    proxmox_vm_qemu.worker_nodes[*].vmid,
    var.worker_vms_ips,
    proxmox_vm_qemu.worker_nodes[*].target_node,
    proxmox_vm_qemu.worker_nodes[*].cores,
    proxmox_vm_qemu.worker_nodes[*].cpu,
    proxmox_vm_qemu.worker_nodes[*].memory
  )
}

output "worker_node_access_info" {
  description = "Formatted access information for all worker nodes"
  value = [
    for vm in proxmox_vm_qemu.worker_nodes : {
      node_name = vm.name
      vm_id     = vm.vmid
      ip        = element(var.worker_vms_ips, count.index)
      ssh       = "ssh ${var.worker_vms_username}@${element(var.worker_vms_ips, count.index)}"
      console   = "https://${vm.target_node}:8006/#v1:0:${vm.target_node}/qemu/${vm.vmid}"
    }
  ]
}

output "all_nodes_summary" {
  description = "Combined summary of both master and worker nodes"
  value = concat(
    formatlist(
      "MASTER: %s | ID: %d | IP: %s | Node: %s | CPU: %d cores | RAM: %d MB",
      [for i, vm in proxmox_vm_qemu.worker_nodes : "${vm.name}-${i+1}"],
      proxmox_vm_qemu.worker_nodes[*].vmid,
      var.worker_vms_ips,
      proxmox_vm_qemu.worker_nodes[*].target_node,
      proxmox_vm_qemu.worker_nodes[*].cores,
      proxmox_vm_qemu.worker_nodes[*].memory
    )
  )
}

output "all_nodes_inventory" {
  description = "Combined Ansible-style inventory for all nodes"
  value = {
    all_nodes = {
      hosts = merge(
        {
          for vm in proxmox_vm_qemu.worker_nodes : vm.name => {
            ansible_host = element(var.worker_vms_ips, count.index)
            ansible_user = var.worker_vms_username
            vm_id        = vm.vmid
            target_node  = vm.target_node
            node_type    = "worker"
          }
        }
      )
    }
  }
}