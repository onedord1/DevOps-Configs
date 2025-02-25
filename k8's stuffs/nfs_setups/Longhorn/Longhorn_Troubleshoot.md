# Longhorn NFS Storage - Scenario Based Troubleshooting

This guide provides step-by-step instructions to troubleshoot Longhorn NFS storage and perform PVC operations effectively.

---

## Table of Contents

1. [Important Notes](#important-notes)
2. [Prerequisites](#prerequisites)
3. [PVC Expansion Steps](#pvc-expansion-steps)
4. [Restrict PVC Operation on Specific Nodes](#restrict-pvc-operation-on-specific-nodes)
    - [Scenario 1: Restrict New PVC Creation Only](#scenario-1-restrict-new-pvc-creation-only)
    - [Scenario 2: Move Existing PVCs and Restrict New PVCs](#scenario-2-move-existing-pvcs-and-restrict-new-pvcs)
5. [Control PVC Data High-Availability](#control-pvc-data-high-availability)

---


## Important Notes

- **Deployment Replicas**: Always scale down deployment replicas to `0` before initiating PVC expansion to avoid errors.  
- **Volume Detachment**: PVC must be in the `Detached` mode before expansion.  
- **UI Access**: Ensure you are familiar with the Longhorn UI layout for selecting and modifying PVCs.

---

## Prerequisites

Before starting the PVC expansion process, ensure the following:

- You have access to the Longhorn UI.
- The Kubernetes deployment associated with the PVC is accessible and manageable.
- You have sufficient permissions to modify PVC and deployment configurations.

---

## PVC Expansion Steps

Follow these steps to expand a Persistent Volume Claim (PVC):

1. **Scale Down Deployment**  
   - Set the deployment replica count to `0`. This ensures the volume can be modified without conflicts.  
     ```bash
     kubectl scale deployment <deployment-name> --replicas=0
     ```

2. **Verify Volume Status**  
   - Wait until the PVC enters the `Detached` mode. You can check the status in the Longhorn UI.  

3. **Select PVC in Longhorn UI**  
   - Open the Longhorn UI.  
   - Locate the PVC need to be expanded in the list of volumes.  
   - Check the box next to the PVC you want to modify.

4. **Expand Volume**  
   - Click the **burger menu** (three dots) beside the **Clone Volume** button.  
   - Select **Expand Volume** from the dropdown menu.  
   - Enter the desired size for the PVC and click **OK**.

5. **Wait for Expansion to Complete**  
   - Monitor the status in the Longhorn UI until the process is completed.

6. **Scale Deployment Back Up**  
   - Once the expansion process is finished, scale the deployment back to the desired replica count.  
     ```bash
     kubectl scale deployment <deployment-name> --replicas=<desired-replica-count>
     ```

---


## Restrict PVC Operation on Specific Nodes

### Scenario 1: Restrict New PVC Creation Only

To prevent new PVCs from being created on a specific node while keeping existing PVCs on the node:

1. Go to the **Node** tab in the Longhorn UI.  
2. Select the node that needs restriction.  
3. From the upper tab, click **Edit Node**.  
4. In the **Node Scheduling** section, set the status to `Disable`.  
5. Leave other options unchanged and press **Save**.  
6. Verify that the node's status is now `Disabled`. This indicates that no new PVC operations will be scheduled on this node.

---

### Scenario 2: Move Existing PVCs and Restrict New PVCs

To move existing PVCs to other nodes and also restrict new PVC operations on the specific node:

1. Go to the **Node** tab in the Longhorn UI.  
2. Select the node that needs restriction.  
3. From the upper tab, click **Edit Node**.  
4. In the **Node Scheduling** section, set the status to `Disable`.  
5. Set **Eviction Requested** to `True`.  
6. Press **Save**.  

   **Note**: Ensure high availability is enabled for volume data. This ensures data can be moved to other nodes without loss.  

7. Wait for the eviction process to complete and verify that:  
   - Existing PVCs have been successfully moved to other nodes.  
   - The node's status is now `Disabled`.  

---


## Control PVC Data High-Availability

To ensure high availability for PVC data, follow these steps:

1. Go to the **Volume** tab in the Longhorn UI.  
2. Select the volume that needs to be set to high-availability mode.  
3. From the **burger menu** on the right side, select **Update Replica Count**.  
4. Set the replica count to match the number of schedulable nodes.  
5. Press **OK** and wait for the operation to complete automatically.  

   **Note**:  
   - Ensure nodes are not evicted and their status is `Schedulable`.  
   - High availability ensures that PVC data is replicated across multiple nodes, allowing Longhorn to manage data seamlessly if one node goes down.

---




