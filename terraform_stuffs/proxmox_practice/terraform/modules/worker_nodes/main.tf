resource "proxmox_vm_qemu" "worker_nodes" {
  count       = var.worker_vms_count
  target_node = var.proxmox_target_node_name
  vmid        = var.worker_vmid_series + count.index + 1
  # vmid        = var.worker_vmid_series + var.master_vms_count + count.index + 1 #combine_with_master_vmid_serial
  name        = "${var.worker_vms_name}-${count.index + 1}"
  desc        = var.worker_vms_description
  agent       = 0
  onboot      = true
  os_type     = var.worker_vms_os_type
  clone       = var.worker_vms_os_template_name
  cores       = var.worker_vms_cpu_core
  sockets     = 1
  cpu         = var.worker_vms_cpu_architecture
  memory      = var.worker_vms_memory
  scsihw      = var.worker_vms_scsi_controller_model
  disks {
    ide {
      ide2 {
        cloudinit {
          storage = var.worker_vms_storage_name
        }
      }
    }
    scsi {
      scsi0 {
        disk {
          size     = var.worker_vms_storage_size
          storage  = var.worker_vms_storage_name
          discard  = true
          iothread = true
        }
      }
    }
  }
  network {
    bridge   = var.worker_vms_network_bridge
    model    = var.worker_vms_network_model
    firewall = true
  }
  ipconfig0 = "ip=${var.worker_vms_ips[count.index]}/24,gw=${chomp(join(".", slice(split(".", var.worker_vms_ips[0]), 0, 3)))}.1"
  ciuser     = var.worker_vms_username
  cipassword = var.worker_vms_password
  sshkeys = var.your_public_key
}
