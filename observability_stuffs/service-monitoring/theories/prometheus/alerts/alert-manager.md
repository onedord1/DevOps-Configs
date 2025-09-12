## Alertmanager

- **Alertmanager is a component of Prometheus that convert alerts from Prometheus to the notification format and send the alerts to the notification channels like Email, Slack, PagerDuty etc**. Alertmanager comes with Web UI to manage the alerts. Alertmanager will expse on port `9093`. If we want to cnfigure Alertmanager behaviour we have to configure the Alertmanager behavior in the `alertmanager.yml` file.

**Functionality of Alertmanager:**

- Can Deduplicate alerts.
- We can silence the alerts.

### Installing Alertmanager

1. **Windows:**

- Download the Alertmanager from the [official site](https://prometheus.io/download/#alertmanager). Select the zip file with OS as `Windows`.
- Extract the downloaded file.
- Go to the extracted directory.
- Run the `alertmanager.exe` file.
- We can access the Alertmanager UI at `http://localhost:9093`.

2. **Linux:**

- Get the alert package from the [official site](https://prometheus.io/download/#alertmanager). Copy the link of the tar.gz file and use the command `wget` to download the file.
```bash
wget https://github.com/prometheus/alertmanager/releases/download/v0.27.0/alertmanager-0.27.0.linux-amd64.tar.gz
```

- Extract the downloaded file.
```bash
tar -xvf alertmanager-0.27.0.linux-amd64.tar.gz
```

- To make ur `alertmanager` installation clean, We can create one Separate directory for `alertmanager` and move the extracted files to that directory.
```bash
sudo mkdir /var/lib/alertmanager
sudo mv alertmanager-0.27.0.linux-amd64/* /var/lib/alertmanager
```

- Go to the `alertmanager` directory.
```bash
cd /var/lib/alertmanager
```

- Now grant our `prometheus` user the ownership and access for the `alertmanager` directory.
```bash
sudo chown -R prometheus:prometheus /var/lib/alertmanager
sudo chown -R prometheus:prometheus /var/lib/alertmanager/*
sudo chmod -R 775 /var/lib/alertmanager
sudo chmod -R 775 /var/lib/alertmanager/*
```

- Now we can execute `alertmanager` binary file if we want. But if we are starting our Alertmanager as Process it will get terminated once we close the terminal. So we have to start the Alertmanager as a service. We can create a service file for the Alertmanager and start the Alertmanager as a service.

- We need to create one storage directory for Alertmanager. We can create one directory called `data` in the `/var/lib/alertmanager` directory.
```bash
sudo mkdir /var/lib/alertmanager/data
```

- Create a service file for Alertmanager.
```bash
sudo vi /etc/systemd/system/alertmanager.service

# Add the below content to the file
[Unit]
Description=Prometheus Alertmanager
Documentation=https://prometheus.io/docs/introduction/overview/
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/var/lib/alertmanager/alertmanager --storage.path="/var/lib/alertmanager/data" --config.file="/var/lib/alertmanager/alertmanager.yml"

SyslogIdentifier=prometheus_alert_manager
Restart=always

[Install]
WantedBy=multi-user.target
```

- Reload the systemd daemon and start the Alertmanager service.
```bash
sudo systemctl daemon-reload
sudo systemctl start alertmanager
sudo systemctl enable alertmanager
```

- To check the status of Alertmanager service.
```bash
sudo systemctl status alertmanager
```

- Now we can access our Alertmanager UI at `http://localhost:9093`.

### Updating `prometheus.yml` file to send alerts to Alertmanager

- We need to update the `prometheus.yml` file to send the alerts to the Alertmanager. We have to add the `alerting` section in the `prometheus.yml` file.

```yaml
# For Alertmanager, We need to add the below configuration at the starting of the file.
alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']
```

Date of notes: 02/07/2024