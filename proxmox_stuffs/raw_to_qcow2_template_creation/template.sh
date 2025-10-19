#!/bin/bash
VMID=6666
TEMPLATE_NAME="ubuntu-cloud-template"
IMAGE_FILE="ubuntu-24.04-minimal-cloudimg-amd64.img"
STORAGE_ID="qcow2-storage"

qm create $VMID --memory 4096 --name $TEMPLATE_NAME --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-pci
qm disk import $VMID $IMAGE_FILE $STORAGE_ID
IMPORTED_VOLUME_ID="${STORAGE_ID}:${VMID}/vm-${VMID}-disk-0.raw"
RAW_DISK_PATH=$(pvesm path $IMPORTED_VOLUME_ID)
QCOW2_DISK_PATH="${RAW_DISK_PATH%.raw}.qcow2"
echo "Converting ${RAW_DISK_PATH} to ${QCOW2_DISK_PATH}..."
qemu-img convert -O qcow2 $RAW_DISK_PATH $QCOW2_DISK_PATH
echo "Removing old RAW disk..."
rm $RAW_DISK_PATH
qm set $VMID --scsi0 ${STORAGE_ID}:${VMID}/vm-${VMID}-disk-0.qcow2
qm set $VMID --ide2 local-lvm:cloudinit
qm set $VMID --boot c --bootdisk scsi0
qm set $VMID --serial0 socket --vga serial0
qm resize $VMID scsi0 10G
qm template $VMID
echo "VM Template ${VMID} created successfully with QCOW2 disk."