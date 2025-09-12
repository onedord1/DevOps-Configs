# Set up a Highly Available Kubernetes Cluster using kubeadm
Follow this documentation to set up a highly available Kubernetes cluster using Ubuntu 20.04 LTS with keepalived and haproxy  This documentation guides you in setting up a cluster with three master nodes, one worker node and two load balancer node using HAProxy and Keepalived.
# We will have

 - Have minimum of 3 master nodes
 - minimum of 1 worker node
 - 2 HA Proxy node to install HAproxy and keepalived

# Set up load balancer nodes (loadbalancer1 & loadbalancer2)

 - Have 2 Server ready to install HA proxy load balancer and keeplived virual ip
 - **Install Keepalived & Haproxy**

    `apt update && apt install -y keepalived haproxy`

- **configure keepalived**
On both nodes create the health check script /etc/keepalived/check_apiserver.sh


	`chmod +x /etc/keepalived/check_apiserver.sh`

- **Create keepalived config /etc/keepalived/keepalived.conf**
- **Enable & start keepalived service**
`systemctl enable --now keepalived`
- **configure HAProxy @ /etc/haproxy/haproxy.cfg**
`systemctl enable haproxy && systemctl restart haproxy`

# Now configure the kubernetes cluster

- follow all the documentation to setup kubernetes cluster
- for master 1,2,3 follow everything until initiating the master node
- on master 1 do this

`sudo kubeadm init --control-plane-endpoint="172.17.17.150:6443#vip_endpoint" --upload-certs --apiserver-advertise-address=172.17.17.151#master_1_endpoint --pod-network-cidr=192.168.123.0/16 --cri-socket /run/containerd/containerd.sock --ignore-preflight-errors Swap`

- now use the output to connect master nad worker nodes

## cavieat
if master node goes down and comes up again, keepalived have to be restarted to sync the changes

# Reference

[just me and open source github](https://github.com/justmeandopensource/kubernetes/tree/master/kubeadm-ha-keepalived-haproxy/external-keepalived-haproxy)
[just me and open source github main](https://github.com/justmeandopensource/kubernetes/tree/master)
for quorum and minimum etcd quatity refer akif's blogpost @linkedin
