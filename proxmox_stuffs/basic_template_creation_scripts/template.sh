#!/bin/bash

# qm create 9999 --memory 8000 --name ubuntu-cloud-image --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-pci
qm create 8888 --memory 8000 --name ubuntu-cloud-image-short --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-pci --cpu host,flags=+aes

qm disk import 8888 ubuntu-24.04-minimal-cloudimg-amd64.img local-lvm

qm set 8888 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-8888-disk-0

qm set 8888 --ide2 local-lvm:cloudinit

qm set 8888 --boot c --bootdisk scsi0

qm set 8888 --serial0 socket --vga serial0

qm resize 8888 scsi0 50G

qm template 8888