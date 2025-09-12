## Node Exporter

**Node Exporter is a Prometheus exporter for collecting metrics from Unix systems**. Node exporter is a official exporter of Prometheus for collecting metrics from Unix systems. It provides a detailed report of the system's resources like CPU, memory, disk, network and more. we can also extend the Node Exporter functionality by using pluggable metric collectors.

### Installation

1. Go to the [Node Exporter download page](https://prometheus.io/download/#node_exporter).

2. Copy the link address of the node exporter tar file. Select the appropriate link based on your OS like Darwin for MacOS, Linux for Linux OS.

3. Open the terminal and run the below command to download the Node Exporter tar file.

```bash
wget https://github.com/prometheus/node_exporter/releases/download/v1.8.1/node_exporter-1.8.1.linux-amd64.tar.gz
```
4. Unzip the downloaded tar file.

```bash
tar xvf node_exporter-1.8.1.linux-amd64.tar.gz
```

5. Change the directory to extracted directory.

```bash
cd node_exporter-1.8.1.linux-amd64
```

6. Execute node exporter binary file.

```bash
./node_exporter
```

Now the Node Exporter is running it will expose the metrics on the port `9100`. We can access the metrics by visiting the URL `http://<node-ip>:9100/metrics`.

### Updating the Scraping Configuration in Prometheus Server

Now we have the Node Exporter running on our Linux server. If we want our Prometheus server to scrape the metrics from the Linux server, we need to update the scraping configuration in the `prometheus.yml` file.

1. Open the `prometheus.yml` file.

```bash
cd /etc/prometheus
vi prometheus.yml
```

2. Under the `scrape_configs` section, add the below configuration. By default, You'll have some configuration in the `scrape_configs` section that is the configuration for scraping the metrics from Prometheus itself. Add the below configuration to scrape the metrics from the Node Exporter.

```yml
  - job_name: 'node-exporter'
    static_configs:
    - targets: ['<node-ip>:9100']
```

3. Save the file and restart the Prometheus server.

```bash
systemctl restart prometheus
```

Now the Prometheus server will scrape the metrics from the Node Exporter running on the Linux server. Just go to Prometheus UI and Click on `Status` -> `Targets` to see the targets and their status. If the target is `UP` then the Prometheus server is able to scrape metrics from Node Exporter.

### Making Node Exporter as a Service

Now we know how to run the Node Exporter manually. But it will stop when we close the terminal. So, we need to make the Node Exporter as a service so that it will run in the background.

1. Create a User and Group for Node Exporter.

```bash
sudo groupadd --system prometheus
sudo useradd -s /sbin/nologin --system -g prometheus prometheus
```

2. Making a Directory for Node Exporter and move the Node Exporter binary file to that directory.

```bash
sudo mkdir /var/lib/node/
sudo mv node_exporter /var/lib/node/
```

3. Create a service file for Node Exporter.

```bash
vi /etc/systemd/system/node_exporter.service
```

**Add the below content to the service file:**

```service
[Unit]
Description=Prometheus Node Exporter
Documentation=https://prometheus.io/docs/introduction/overview/
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/var/lib/node/node_exporter

SyslogIdentifier=prometheus_node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
```

4. Change the owner of the directory and grant access to `prometheus` user.

```bash
sudo chown -R prometheus:prometheus /var/lib/node/
sudo chown -R prometheus:prometheus /var/lib/node/* # For folders under /var/lib/node directory
sudo chmod -R 755 /var/lib/node/
sudo chmod -R 755 /var/lib/node/*
```

5. Reload the systemd manager configuration.

```bash
sudo systemctl daemon-reload
```

6. Start the Node Exporter service.

```bash
sudo systemctl start node_exporter
```

7. Enable the Node Exporter service to start on boot.

```bash
sudo systemctl enable node_exporter
```

8. Check the status of the Node Exporter service.

```bash
sudo systemctl status node_exporter
```

Now the Node Exporter is running as a service. We can access the metrics by visiting the URL `http://<node-ip>:9100/metrics`.

Date of notes: 01/07/2024