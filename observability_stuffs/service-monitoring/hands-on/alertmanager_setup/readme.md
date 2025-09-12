This guide will set up Alertmanager for VMs' CPU, memory, and storage pressure alerts to be sent to Google Chat or relevant channels.

First and foremost, set up Alertmanager as a systemd service by following the steps below.

**Step 1: Download & Set Up Alertmanager**

Go to the VM/SERVER's `/opt/alertmanager`, create the directory if necessary, then download the binary using the commands below:

```bash
sudo mkdir -p /opt/alertmanager
cd /opt/alertmanager
curl -LO https://github.com/prometheus/alertmanager/releases/download/v0.28.1/alertmanager-0.28.1.linux-amd64.tar.gz
tar -xvf alertmanager-*.tar.gz
mv alertmanager-* alertmanager
```

Now create a systemd service under `/etc/systemd/system/`:

```bash
sudo nano /etc/systemd/system/alertmanager.service
```

Add the following configuration:

```bash
[Unit]
Description=Alertmanager
Wants=network-online.target
After=network-online.target

[Service]
User=nobody
ExecStart=/opt/alertmanager/alertmanager --config.file=/opt/alertmanager/alertmanager.yml --storage.path=/var/lib/alertmanager
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

**Start the Alertmanager**

```bash
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable alertmanager
sudo systemctl start alertmanager
```

**Check the Status of Alertmanager**

```bash
sudo systemctl status alertmanager
```

Now the Alertmanager should be up and running on port 9093.

**For Sync with Prometheus Config**

The `prometheus.yaml` should be located under `/opt/prometheus`. Add the following line inside `prometheus.yml` to sync with Alertmanager:

```bash
alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - localhost:9093 # In this case, Prometheus and Alertmanager are set up under the same VM
```

To add desired node rules for VMs (CPU, memory, disk pressure), enable the rules section inside `prometheus.yml`:

```bash
rule_files:
   - "rules/node_rules.yml"
```

A reference [node_rules](https://172.17.19.247/devops/config-yaml/-/blob/dev/aes-monitor/vm-monitor/alertmanager_setup/configs/node_rules.yml) config can be found in the provided link.

In this case, to send alerts to the Google Chat workspace using webhooks with the help of Calert, first configure Alertmanager to communicate with Calert, which runs as a Docker container on port 6000.

**Configure the Receiver Inside `alertmanager.yml`**

```bash
receivers:
  - name: 'googlechat'
    webhook_configs:
      - url: 'http://localhost:6000/dispatch'
```

A complete reference [alertmanager.yml](https://172.17.19.247/devops/config-yaml/-/blob/dev/aes-monitor/vm-monitor/alertmanager_setup/configs/alertmanager.yml) config can be found in the link.


For Calert configuration, ensure the webhook URL from Google Chat is placed into `config.toml`. If you need to use the reference `config.toml`, it is located in [config.toml](https://172.17.19.247/devops/config-yaml/-/blob/dev/aes-monitor/vm-monitor/alertmanager_setup/configs/calert/config.toml). Additionally, a reference message template for Calert can be found in [Message tmpl](https://172.17.19.247/devops/config-yaml/-/blob/dev/aes-monitor/vm-monitor/alertmanager_setup/configs/calert/message.tmpl).