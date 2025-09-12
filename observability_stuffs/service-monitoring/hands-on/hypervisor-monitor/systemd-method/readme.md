For hypervisor monitoring with Prometheus, the PVE Exporter will be used. Follow the steps below to set it up on your Proxmox server.

## Step 1: Install Necessary Python Dependencies

Install the required Python packages using the following command:

```bash
sudo apt install python3-pip python3-venv
```

Prepare a new environment for the PVE Exporter:

```bash
python3 -m venv /opt/prometheus-pve-exporter
```

Install the PVE Exporter into the new environment:

```bash
/opt/prometheus-pve-exporter/bin/pip install prometheus-pve-exporter
```

Check whether the `pve_exporter` is executable:

```bash
/opt/prometheus-pve-exporter/bin/pve_exporter --help
```

## Step 2: Create a Proxmox VE API User

Create the API user with the following command:

```bash
pveum user add prometheus@pve -password "securePassword"
```

Set the user role to `PVEAuditor`:

```bash
pveum acl modify / -user prometheus@pve -role PVEAuditor
```

Ensure that this user cannot log in interactively:

```bash
useradd -s /bin/false prometheus
```

Generate an API token for that user:

```bash
pveum user token add prometheus@pve monitoring --comment "Token for monitoring"
```

## Step 3: Configure the PVE-Exporter

Create a folder at `/etc`:

```bash
mkdir -p /etc/prometheus
```

Then create `pve.yml` inside that folder and write the following configurations:

```yaml
default:
  user: prometheus@pve
  token_name: monitoring
  token_value: 50779d8b-3b7d-45fa-85d0-f90572e79471
  verify_ssl: false
```

Start on boot-up by creating a systemd service file:

```bash
cat <<EOF> /etc/systemd/system/prometheus-pve-exporter.service
[Unit]
Description=Prometheus exporter for Proxmox VE
Documentation=https://github.com/znerol/prometheus-pve-exporter

[Service]
Restart=always
ExecStart=/opt/prometheus-pve-exporter/bin/python /opt/prometheus-pve-exporter/bin/pve_exporter --config.file /etc/prometheus/pve.yml

[Install]
WantedBy=multi-user.target
EOF
```

Then reload systemd and start the unit:

```bash
systemctl daemon-reload && systemctl enable --now prometheus-pve-exporter
```

## Step 4: Prometheus Integration

Create a file named `local_hypervisors.yml` and open it with your preferred text editor. Follow the format below:

```yaml
- labels:
    target_name: dev_proxmox 
  targets:
      - 172.17.17.17:9221
```

A complete reference can be found here: [Local_Hypervisors](https://172.17.19.247/devops/config-yaml/-/blob/dev/aes-monitor/hypervisor-monitor/prometheus/local_hypervisors.yml).

Lastly, refer to the created files in Prometheus as a job:

```yaml
scrape_configs:
      - job_name: 'hypervisors'
    file_sd_configs:
      - files:
          - '/opt/prometheus/files_sd/local_hypervisors.yml'
    scheme: http
    metrics_path: '/metrics'
    basic_auth:
      username: 'aesmonitor'   # if authentication is needed
      password: 'UdnBf00R@z06'
    tls_config:
      ca_file: '/opt/prometheus/ssl/node_exporter.crt' # if using a self-signed certificate
      insecure_skip_verify: true
    relabel_configs:
      - source_labels: ['target_name']
        target_label: 'target_name'
```

A complete reference can be found here: [Prometheus](https://172.17.19.247/devops/config-yaml/-/blob/dev/aes-monitor/hypervisor-monitor/prometheus/prometheus.yml).


