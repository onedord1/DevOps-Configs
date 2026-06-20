#!/bin/bash


# generate ssh key
echo "installing ssh profile .. .. .."
yes y | ssh-keygen -t rsa -b 4096 -q -N "" -f /home/$(whoami)/.ssh/id_rsa

echo "installing required packages .. .. .."
# check if ansible exist, if! then install
if command -v ansible &> /dev/null; then
    echo "exist"
else
    sudo apt update -y
    sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y
    sudo apt  install  software-properties-common -y
    sudo add-apt-repository  --yes  --update  ppa:ansible/ansible
    sudo DEBIAN_FRONTEND=noninteractive apt  install  ansible  -y
    ansible  --version
fi

# check if jq exist, if! then install
if command -v jq &> /dev/null; then
    echo "exist"
else
    sudo snap install jq
fi

# check if sshpass exist, if! then install
if command -v sshpass &> /dev/null; then
    echo "exist"
else
    sudo apt-get install sshpass -y
fi

# Get auth_username and password from inventory file(common username and password of master and worker servers)
# Get the list of hosts and ports from ansible-inventory
ansible_cfg="ansible.cfg"
hosts=$(ansible-inventory -i inventory.ini --list | jq -r '.["_meta"].hostvars | .[].ansible_host')
ports=$(ansible-inventory -i inventory.ini --list | jq -r '.["_meta"].hostvars | .[].ansible_port')
hostnames=$(ansible-inventory -i inventory.ini --list | jq -r '[.masters.hosts[], .workers.hosts[]] | unique | .[]')
auth_username=$(ansible-inventory -i inventory.ini --list | jq -r '.["_meta"].hostvars |  .[].auth_username' | head -n 1)
auth_password=$(ansible-inventory -i inventory.ini --list | jq -r '.["_meta"].hostvars |  .[].auth_password' | head -n 1)

# Convert to arrays
IFS=$'\n' read -r -d '' -a hosts_array <<< "$hosts"
IFS=$'\n' read -r -d '' -a ports_array <<< "$ports"
IFS=$'\n' read -r -d '' -a hostnames_array <<< "$hostnames"

# Declare a dictionary for hosts and ports
declare -A host_port_map

# Populate the map
for index in "${!hostnames_array[@]}"; do
    hostname="${hostnames_array[$index]}"
    ip="${hosts_array[$index]}"
    port="${ports_array[$index]}"
    host_port_map["$hostname"]="{ip:$ip, port:$port}"
done

# SSH COPY ID TO ALL HOSTS
for hostname in "${!host_port_map[@]}"; do
    entry="${host_port_map[$hostname]}"
    ip=$(echo "$entry" | awk -F'[,:]' '{print $2}' | tr -d ' ')
    port=$(echo "$entry" | awk -F'[,:]' '{print $4}' | tr -d ' ' | tr -d '}')
    ssh-keyscan -H -p $port $ip >> /home/$(whoami)/.ssh/known_hosts
    sshpass -p "$auth_password" ssh-copy-id -f -i /home/$(whoami)/.ssh/id_rsa.pub -p $port "$auth_username@$ip"
done

# update username in ansible cfg file
if [ -f "$ansible_cfg" ]; then
    # Replace remote_user value using sed
    sed -i "s/^remote_user = .*/remote_user = $auth_username/" "$ansible_cfg"
    # echo "Updated remote_user to $username in $ansible_cfg"
else
    echo "Error: $ansible_cfg not found."
fi

# BOOTSTRAP ANSIBLE SCRIPT USER TO ALL HOSTS
ansible-playbook 01.bootstrap_user.yaml --become -e "ansible_become_password=$auth_password"


###### INITIALIZE K8S CLUSTER
printf "\e[1;33mINITIATION STARTED:\e[0m \e[1;32m%s\e[0m\n" "Initializing Kubernetes Cluster 1.31"
printf "################################################################\n"

# ansible-playbook 02.disableswap.yaml 03.sysctlstuff.yaml 04.install_containerd.yaml 05.containerd_cggroup.yaml 06.kubeadm-prereqs.yaml 07.kubeadm_done.yaml 08.master_init.yaml 09.config-add.yaml 10.join-worker.yaml 11.add-root-kubeconfig.yaml 12.calico-pod-network-3.28.yaml 13.nfs.yaml 14.metallb-0.14.5.yaml 15.watcher.yaml
# ansible-playbook 02.disableswap.yaml 03.sysctlstuff.yaml 04.install_containerd.yaml 05.containerd_cggroup.yaml 06.kubeadm-prereqs.yaml 07.kubeadm_done.yaml 08.master_init.yaml 09.config-add.yaml 10.join-worker.yaml 11.add-root-kubeconfig.yaml 12.calico-pod-network-3.28.yaml
# ansible-playbook 02.disableswap.yaml 03.sysctlstuff.yaml 04.install_containerd.yaml 05.containerd_cggroup.yaml 06.kubeadm-prereqs.yaml 07.kubeadm_done.yaml 08.master_init.yaml 09.config-add.yaml 10.join-worker.yaml 11.add-root-kubeconfig.yaml 12.calico-pod-network-3.28.yaml 13.nfs.yaml 14.metallb-0.14.5.yaml 15.watcher.yaml 16.ssh-allow.yaml

ansible-playbook 02.disableswap.yaml 03.sysctlstuff.yaml 04.install_containerd.yaml 05.containerd_cggroup.yaml 06.kubeadm-prereqs.yaml 07.kubeadm_done.yaml 08.master_init.yaml 09.config-add.yaml 10.join-worker.yaml 11.add-root-kubeconfig.yaml 12.calico-pod-network-3.28.yaml 13.long_prereq.yaml 14.longhorn_nfs_standard.yaml 15.metallb-0.14.5.yaml 16.watcher.yaml 17.ssh-allow.yaml

# ansible-playbook 02.disableswap.yaml 03.sysctlstuff.yaml 04.install_containerd.yaml 05.containerd_cggroup.yaml 06.kubeadm-prereqs.yaml 07.kubeadm_done.yaml 08.master_init.yaml 09.config-add.yaml 10.join-worker.yaml 11.add-root-kubeconfig.yaml 12.calico-pod-network-3.28.yaml 15.metallb-0.14.5.yaml nfs_subdir_provisioner.yaml 16.watcher.yaml 17.ssh-allow.yaml


# ansible-playbook 02.disableswap.yaml 03.sysctlstuff.yaml 04.install_containerd.yaml 05.containerd_cggroup.yaml 06.kubeadm-prereqs.yaml 07.kubeadm_done.yaml 08.master_init.yaml 09.config-add.yaml 10.join-worker.yaml 11.add-root-kubeconfig.yaml 12.calico-pod-network-3.28.yaml 14.metallb-0.14.5.yaml 15.watcher.yaml 16.ssh-allow.yaml

###### DONE

printf "\n\n\n\e[1;33mINITIATED:\e[0m \e[1;32m%s\e[0m\n" "Kubernetes Cluster Is Ready"
printf "#########################################\n"
printf "#########################################\n"

REMOTE_USER=$(ansible-config dump | grep DEFAULT_REMOTE_USER | awk '{print $3}')
IP=$(ansible-inventory --inventory inventory.ini --list  | jq -r '.["_meta"].hostvars.master1.ansible_host')
printf "\n\e[1;34mTo interact with the cluster:\n\e[0m\n"
printf "1. \e[1;36mSSH into the master node:\n \t\e[0m ssh $REMOTE_USER@$IP -p itsport \n\n"
printf "2. \e[1;36mTest the cluster:\n\t\e[0m kubectl get po -A\n\n"