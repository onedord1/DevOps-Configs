## Installation and Setup of k0sctl

### Install k0sctl using Homebrew
```bash
brew install k0sproject/tap/k0sctl
```

### Initialize Configuration
Generate the initial configuration file:
```bash
k0sctl init --config k0sctl.yaml
```

Then edit the `hosts` section in `k0sctl.yaml` to match your environment such as:
- Control plane and worker nodes IP addresses
- SSH ports
- Your local SSH keys that are authorized to access the nodesz


### Install Cluster
Install the cluster:
```bash
k0sctl apply --config k0sctl.yaml
```

### Get Kubeconfig
Generate the kubeconfig file (ensure you are in the same directory as k0sctl.yaml):
```bash
k0sctl kubeconfig
```

Alternatively, save directly to kubectl config:
```bash
k0sctl kubeconfig > ~/.kube/config
```

### Cleanup
To delete the cluster:
```bash
k0sctl reset --config /path/to/k0sctl.yaml
```

### Reference
For more information, visit the [official k0s documentation](https://docs.k0sproject.io/stable/)