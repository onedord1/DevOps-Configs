# kubeadm + Cilium (kube-proxy-free) — Ansible Automation

Production-grade, fully env-driven Ansible automation that builds a Kubernetes
**1.32** cluster with **Cilium** as the one and only networking layer:

- **kube-proxy is completely removed** — Cilium runs in `kubeProxyReplacement: true` (eBPF) mode.
- **No MetalLB** — `type: LoadBalancer` IPs are served by Cilium **L2 Announcements**
  (`CiliumLoadBalancerIPPool` + `CiliumL2AnnouncementPolicy`).
- **Hubble** observability (relay + UI) enabled.
- Console output is beautified locally by the bundled `k8s_beautified` callback.

This automates the manual runbook in
[`kubeadm_cluster_setup_with_cilium.md`](./kubeadm_cluster_setup_with_cilium.md).

---

## Topology

| Role          | Default host (from `.env`) |
|---------------|----------------------------|
| control-plane | `43.204.212.220`           |
| worker-01     | `43.204.109.185`           |
| worker-02     | `13.204.82.125`            |

Single control plane + two workers. Everything is configurable — nothing is
hard-coded in the roles.

---

## Layout

```
cilium-CNI/
├── ansible.cfg                  # wires in the k8s_beautified callback + SSH/sudo
├── requirements.yml             # Galaxy collections
├── .env.example                 # ALL tunables live here (copy to .env)
├── callback_plugins/
│   └── k8s_beautified.py         # neon stdout callback (local pretty logs)
├── inventories/production/
│   ├── hosts.yml                # env-driven inventory
│   └── group_vars/              # all.yml + per-group vars
├── roles/
│   ├── common/                  # swap, kernel modules, sysctl
│   ├── containerd/              # CRI runtime, systemd cgroups
│   ├── kubernetes/              # pinned kubelet/kubeadm/kubectl
│   ├── control_plane/           # kubeadm init (kube-proxy skipped) + kubeconfig
│   ├── cilium/                  # Helm install + L2 LoadBalancer
│   └── worker/                  # node join
├── playbooks/
│   ├── site.yml                 # full deploy + verification
│   └── reset.yml                # DESTRUCTIVE teardown
└── scripts/bootstrap.sh         # deps + connectivity check + deploy
```

---

## Prerequisites

- A control machine with **Ansible 2.14+**, `python3`, and SSH access to all nodes.
- Ubuntu 22.04 target nodes with a sudo-capable SSH user and key-based auth.
- For **L2 announcements to actually work**, the LoadBalancer IP range
  (`CILIUM_LB_IP_CIDR`) must live on the **same L2 segment** as the nodes (ARP).
  On clouds that don't provide flat L2 between instances (e.g. EC2 across
  subnets), L2 mode won't announce — use a flat L2 network or switch to BGP.

---

## Quick start

```bash
cd cilium-CNI

# 1. configure
cp .env.example .env
$EDITOR .env            # set IPs, SSH user/key, CIDRs, LB range
source .env

# 2. deploy (installs collections, checks SSH, then runs site.yml)
./scripts/bootstrap.sh
```

Or run the steps manually:

```bash
ansible-galaxy collection install -r requirements.yml -p collections
ansible all -m ping
ansible-playbook playbooks/site.yml
```

---

## Configuration (env vars)

Everything is driven from `.env` — see `.env.example` for the full list. Key ones:

| Variable | Purpose | Default |
|----------|---------|---------|
| `K8S_CONTROL_PLANE_IP` / `K8S_WORKER1_IP` / `K8S_WORKER2_IP` | Node SSH IPs | — |
| `K8S_SSH_USER` / `K8S_SSH_PORT` / `K8S_SSH_KEY` | SSH connection | `ubuntu` / `22` / `~/.ssh/id_rsa` |
| `K8S_MINOR_VERSION` | Kubernetes apt channel | `1.32` |
| `CILIUM_VERSION` | Cilium chart version | `1.16.6` |
| `HELM_VERSION` | Helm CLI (official get.helm.sh binary, SHA256-verified) | `v3.16.4` |
| `K8S_POD_CIDR` / `K8S_SERVICE_CIDR` | Cluster networking | `192.168.0.0/16` / `10.96.0.0/12` |
| `K8S_API_ADVERTISE_ADDRESS` | API advertise IP (blank = auto-detect NIC IP) | _auto_ |
| `K8S_SERVICE_HOST` | Address Cilium uses for the API server (blank = control-plane IP) | _auto_ |
| `CILIUM_LB_IP_CIDR` | LoadBalancer IP pool announced over L2 | `172.17.17.200/29` |
| `CILIUM_L2_INTERFACE` | Regex of NICs that announce LB IPs | `^e(n|th).*` |
| `CILIUM_L2_WORKERS_ONLY` | Announce from workers only | `true` |

> On NATed clouds the public Elastic IP is **not** bound to the NIC, so the
> advertise/service IP defaults to each node's auto-detected **primary IPv4**
> (`ansible_default_ipv4.address`). Override per environment via env vars.

---

## How kube-proxy is replaced

1. `kubeadm init` runs with `skipPhases: [addon/kube-proxy]` (set both in the
   rendered kubeadm config and on the CLI), so the kube-proxy DaemonSet is
   never created.
2. Cilium is installed with `kubeProxyReplacement: true`, `k8sServiceHost`, and
   `k8sServicePort` so it programs service load-balancing in eBPF.
3. `site.yml` asserts the `kube-proxy` DaemonSet is absent before finishing.

## How LoadBalancer IPs work (no MetalLB)

- `l2announcements.enabled: true` + `externalIPs.enabled: true` in the Helm values.
- A `CiliumLoadBalancerIPPool` hands IPs from `CILIUM_LB_IP_CIDR` to
  `type: LoadBalancer` Services.
- A `CiliumL2AnnouncementPolicy` ARP-announces those IPs from the selected NICs
  (workers only by default).

Test it after deploy:

```bash
kubectl create deploy nginx --image=nginx
kubectl expose deploy nginx --type=LoadBalancer --port=80
kubectl get svc nginx -w      # EXTERNAL-IP comes from CILIUM_LB_IP_CIDR
```

---

## Pretty local logs

The `k8s_beautified` stdout callback is wired in via `ansible.cfg`
(`stdout_callback = k8s_beautified`, `callback_plugins = callback_plugins`).
It renders neon spinners, per-play progress bars and framed error panels on a
TTY, and **automatically falls back to clean plaintext** when piped to a file or
when `NO_COLOR` / `ANSIBLE_NOCOLOR` is set. `ANSIBLE_FORCE_COLOR=1` (in
`.env.example`) keeps colour through wrappers.

---

## Teardown

```bash
ansible-playbook playbooks/reset.yml   # DESTRUCTIVE — wipes cluster state
```

---

## Security notes

- No secrets in the repo: connection details and tokens come from the
  environment / are generated at runtime. `.env` and key material are git-ignored.
- Join tokens are created with a short 2h TTL and kept in play memory only.
- kubeconfig is installed `0600`, kubeadm config `0600`.
- SSH uses key-based auth only (`PreferredAuthentications=publickey`).
- Set `ANSIBLE_HOST_KEY_CHECKING=True` and pre-populate `known_hosts` for a
  hardened run (default is `False` for first-run convenience).
