output "master_node_details" {
  description = "Map of master VMs with VM ID, name, IP, and other metadata"
  value       = module.master_vms.master_node_details
}

output "master_vm_ids" {
  description = "List of VM IDs for all master nodes"
  value       = module.master_vms.master_node_vmids
}

output "master_vm_ips" {
  description = "List of IP addresses for master nodes"
  value       = module.master_vms.master_node_ips
}

output "master_ssh_commands" {
  description = "SSH commands for connecting to each master node"
  value       = module.master_vms.master_node_ssh_connections
}

output "worker_node_details" {
  description = "Map of worker VMs with VM ID, name, IP, and other metadata"
  value       = module.worker_vms.worker_node_details
}

output "worker_vm_ids" {
  description = "List of VM IDs for all worker nodes"
  value       = module.worker_vms.worker_node_vmids
}

output "worker_vm_ips" {
  description = "List of IP addresses for worker nodes"
  value       = module.worker_vms.worker_node_ips
}

output "worker_ssh_commands" {
  description = "SSH commands for connecting to each worker node"
  value       = module.worker_vms.worker_node_ssh_connections
}
