
# tested on ubuntu 22.04
# this script is made for master,worker server in office space with private ip,made reachable by a public ip,
# Summary

This ansible script does the following

1. installs required packages on master and worker nodes(e.g containerd, kubelet etc) and sets up the environment to initiate Kubernetes cluster

2. initiates the k8s cluster

3. joins worker nodes @ initiation

4. joins worker nodes later

5. installs nfs-subdirectory external provisioner controller via helm (we must have nfs server set up previously)

6. installs network plugin calico

7. set up metallb controller

  

# Prereqs

## on remote(go server)
- have a user on the remote machine with sudoer privileges (not root)
- add user to the sudoer file with nopasswd permission
`
  "$USERNAME ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
`


## on the worker and master nodes

- have same username across all the master and worker nodes

- have same password across all the master and worker nodes

- user must be a sudo user

- must have ssh installed across all the servers and enabled

<hr>

- update inventory.ini file
  
# RUN

```bash

chmod  +x  ./00.setup-k8s.sh

./00.setup-k8s.sh

```
