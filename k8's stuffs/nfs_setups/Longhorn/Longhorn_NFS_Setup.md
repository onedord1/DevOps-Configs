# Install Longhorn with NFS Local Server using Helm Chart in Kubernetes Cluster


## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. Read the steps carefully and apply those based on your requirements as well as environments

### Prerequisites


```
Existing K8's Cluster with Helm Install ['https://helm.sh/docs/intro/install/' - For Helm]
NFS Local Server
Make Sure Your cluster resource are available enough 
In my case 
    - 8vcpu
    - 8GB Memory
    - 100GB Storage each Kubernetes Nodes

```

### Steps

On your K8's cluster at first deploy the longhorn stuffs such as controller, csi driver, resizer etc..
In this case, we will use values yml from ref link : [https://github.com/longhorn/longhorn/blob/master/chart/values.yaml]
This will optimize longhorn stuffs according to needs..

Then on the console run 

`helm repo add longhorn https://charts.longhorn.io`
`helm repo update`
`helm install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace --version 1.7.2 --values values.yml`



"In my case the longhorn version is 1.7.2 in that time"

Then run kubectl below command to watch the activity realtime 

`watch kubectl -n longhorn-system get pod`


{Ref : https://longhorn.io/docs/1.7.2/deploy/install/install-with-helm/}


## Accessing the longhornUI

Firstly, run the kubectl command to see the services 

`kubectl -n longhorn-system get svc`

This will come with output of 

"longhorn-frontend" & "longhorn-backend" with *ClusterIP*

Expose the *External-IP* of 'longhorn-frontend'

In my case, I changed service type on yaml config file from *ClusterIP* to *LoadBalancer* to expose this *External-IP*

{Ref : https://longhorn.io/docs/1.7.2/deploy/accessing-the-ui/}

For Ingress Please refer the official Documents below

<a>https://longhorn.io/docs/1.7.2/deploy/accessing-the-ui/longhorn-ingress/</a>

## NFS Setup

After accessing the UI go to *Setting>General*
Scroll Down until you find tab *Backup : Backup Target*
Write Down the IP and saving path like below

`nfs://<your_nfs_ip_address>:<data_saved_location/>`

e.g nfs://192.14.1.0:/data/mnt/data/



## Pre-Req for Backup & Restore
- create a kubeadm cluster
- create a nfs server

## Longhorn installation 
- Edit values.yml 
	- Set kubernetesClusterAutoscalerEnable: ture
		By default, Longhorn blocks Kubernetes Cluster Autoscaler from scaling down nodes because : https://longhorn.io/docs/archives/1.3.0/high-availability/k8s-cluster-autoscaler/
	- edit the nfs server location 
```
defaultSettings:
	backupTarget: nfs://172.17.17.7:/var/k8-nfs/data
```
- Apply longhorn helm chart with custom values
`helm repo add longhorn https://charts.longhorn.io`
`helm repo update`
`helm install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace --version 1.7.2 --values values.yml`

- Browse Longhorn UI 
		- if you apply the values.yml config there already expose the longhorn_frontend_ui by using 'Nodeport' just run the `kubectl get svc -A` command and copy the port number. Now on the browser write the worker_nodes_ip:port for browsing the UI.  

# Data Propagation (Backup & Restore)

## Backup Process
1. PVC backup in longhorn
- Apply nginx deployment and pvc yml. Here make sure in your PVC yaml your storageClass is longhorn
`kubectl apply -f nginxwithPVC.yaml`
- Exec into nginx pod and add some data into '/usr/share/nginx/html' 
- On the longhorn UI, go to volume tab and select the pvc's and then click 'Create Backup'
- If the backupTarget is up and running it should create backup successfully and stored into nfs server as well. On the Backup tab you will see the visuals. 

2. ETCD backup
	- backup your etcd database

## Restore Process
1. ETCD Restore 
	- In your fresh cluster restore your ETCD & restart nodes

2. 
- In-case, the cluster or nodes will go down still we can retrive our data from longhorn backup.
	- For that, when your get back to your cluster again with longhorn, make sure your backupTarget is set to previous nfs server location and previous format. 
	- Delete the existing deployments and pvc's if exists. Because, after restoring etcd  we have pvc's but dont have the pvc's volume on the respective nodes. This will result pod readiness state pending.
	- Now, In the longhornUI go to the Backup tab select the backups that would previously created and Select 'Restore Latest Backup'.
	- For the Name section select "Use Previous Name" then Select 'Access Mode' ReadWriteMany' or relevant as before backup and rest of all leave as it is then press OK. it will take some time to restore.
	- After that, go to volume tab and select the restored volume and from the upper dropdown menu  select 'Create PV/PVC' . This will create pvc in the cluster and mount the volume in respective nodes. 
	- Finally, apply the deployment yml file to restore pod with previous files in it.


## Continuous Backup

- For Continuous Backup We need to create a Recurring Job
	- From the longhorn tab go to Volume tab click the volume that you want to backup continuously then scroll down.
	-  On the Recurring Job Schedule Section click Add from right upper corner then set the Task to 'Backup' and below edit the Cron t '* * * * *' for every minute then press OK. Now the longhorn check the volume for updates every time. 

## For Dynamically Provisioning 

Apply your pv & pvc config yaml and your pod to claim the pvc first & for dynamic change edit the PV file and apply it it will automatically update on the cluster

Example ::

The PVC yml :

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: xxxxx
spec:
  storageClassName: longhorn
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Mi

```
The PV yaml

```

apiVersion: v1
kind: PersistentVolume
metadata:
  name: pvc-d58accfa-e5da-4b87-928f-68d3ffa720c8
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 500Mi
  claimRef:
    apiVersion: v1
    kind: PersistentVolumeClaim
    name: xxxxx
    namespace: default
  csi:
    driver: driver.longhorn.io
    fsType: ext4
    volumeAttributes:
      dataLocality: disabled
      disableRevisionCounter: "true"
      fromBackup: ""
      fsType: ext4
      numberOfReplicas: "3"
      staleReplicaTimeout: "30"
      unmapMarkSnapChainRemoved: ignored
    volumeHandle: pvc-d58accfa-e5da-4b87-928f-68d3ffa720c8
  persistentVolumeReclaimPolicy: Retain
  storageClassName: longhorn
  volumeMode: Filesystem
status:
  phase: Bound   

```

Edit the *spec.capacity.storage* in the PV yml according to your needs
this will aumatically update the pvc as well 

Make sure your storage class have *allowExpansion* is set to `true` at longhorn storage class

---
END

