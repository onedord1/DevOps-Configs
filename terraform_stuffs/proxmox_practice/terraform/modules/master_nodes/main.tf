resource "proxmox_vm_qemu" "master_nodes" {
  count       = var.master_vms_count
  target_node = var.proxmox_target_node_name
  vmid        = var.master_vmid_series + count.index + 1
  name        = var.master_vms_name
  desc        = var.master_vms_description
  agent       = 0
  onboot      = true
  os_type     = var.master_vms_os_type
  clone       = var.master_vms_os_template_name
  cores       = var.master_vms_cpu_core
  sockets     = 1
  cpu         = var.master_vms_cpu_architecture
  memory      = var.master_vms_memory
  scsihw      = var.master_vms_scsi_controller_model
  disks {
    ide {
      ide2 {
        cloudinit {
          storage = var.master_vms_storage_name
        }
      }
    }
    scsi {
      scsi0 {
        disk {
          size     = var.master_vms_storage_size
          storage  = var.master_vms_storage_name
          discard  = true
          iothread = true
        }
      }
    }
  }
  network {
    bridge   = var.master_vms_network_bridge
    model    = var.master_vms_network_model
    firewall = true
  }
  ipconfig0  = "ip=${var.master_ips[count.index]}/24,gw=${chomp(join(".", slice(split(".", var.master_ips[0]), 0, 3)))}.1"
  ciuser     = var.master_vms_username
  cipassword = var.master_vms_password
  sshkeys    = var.your_public_key
}
