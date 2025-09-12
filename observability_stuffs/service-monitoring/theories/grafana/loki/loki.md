## Loki Introduction

- ***Loki is a horizontally scalable, highly available, multi-tenant log aggregation system inspired by Prometheus***. 
- It can collect, store and query large volumes of logs.
- It doesn't have any web UI to visualize logs. But it have very good integration with Grafana. We can view and visualize logs in Grafana using Loki.
- Loki is based on `Chunk based storage`. It chunks the logs into small parts and compresses them.

### Loki Working

- We need to install a agent called `Promtail` on the servers where our applications are running and where we want to collect logs.
- Then we need configure Promtail by specifying the location of our log files and file name. Promtail will read the logs from the log files and push them to Loki.
- Then we can use Grafana to query the logs and visualize them by using Loki as a datasource

### Installation of Loki and Promtail

1. **Using Docker**

**Prerequisites:** Docker should be installed on the system.

- Create a `docker-compose.yml` file with the below content.

```yaml
version: "3"

networks:
  loki:

services:
  loki:
    image: grafana/loki:2.9.2
    ports:
      - "3100:3100"
    command: -config.file=/etc/loki/local-config.yaml
    networks:
      - loki

  promtail:
    image: grafana/promtail:2.9.2
    volumes:
      - /var/log:/var/log
    command: -config.file=/etc/promtail/config.yml
    networks:
      - loki

  grafana:
    environment:
      - GF_PATHS_PROVISIONING=/etc/grafana/provisioning
      - GF_AUTH_ANONYMOUS_ENABLED=true
      - GF_AUTH_ANONYMOUS_ORG_ROLE=Admin
    entrypoint:
      - sh
      - -euc
      - |
        mkdir -p /etc/grafana/provisioning/datasources
        cat <<EOF > /etc/grafana/provisioning/datasources/ds.yaml
        apiVersion: 1
        datasources:
        - name: Loki
          type: loki
          access: proxy 
          orgId: 1
          url: http://loki:3100
          basicAuth: false
          isDefault: true
          version: 1
          editable: false
        EOF
        /run.sh
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    networks:
      - loki
```
- Run the below docker command to start the Loki, Promtail and Grafana services.

```bash
docker-compose up -d
```

2. **On Linux using Commands**

- To install `Loki` on Linux, we can use the following commands.

```bash
sudo apt-get update
sudo apt-get install loki
```

- To install `Promtail` on Linux, we can use the following commands.

Navigate to Loki [Releases page](https://github.com/grafana/loki/releases) and choose the package according to your system architecture.

```bash
wget https://github.com/grafana/loki/releases/download/v2.9.9/loki-linux-amd64.zip
unzip loki-linux-amd64.zip
sudo mv loki-linux-amd64 /usr/local/bin/loki
sudo chmod a+x /usr/local/bin/loki
```
- Now we need to create a configuration file for Promtail. First, Create a Directory for Promtail Configuration

```bash
sudo mkdir -p /etc/promtail
```

- Now create a file named `config.yml` with the following content.

```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://localhost:3100/loki/api/v1/push

scrape_configs:
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: varlogs
          __path__: /var/log/*log
```
- Now we can start `Promtail` as script. But the better way is to create Promtail as a service, create a file named `promtail.service` with the following content.

```bash
sudo nano /etc/systemd/system/promtail.service
```

```bash
[Unit]
Description=Loki Promtail
After=network.target

[Service]
ExecStart=/usr/local/bin/promtail -config.file=/etc/promtail/config.yml
Restart=always

[Install]
WantedBy=default.target
```

- Now start the Promtail service.

```bash
sudo systemctl start promtail
```

Finally we can now use **Loki as a datasource in Grafana to query and visualize logs**. Now we need to generate logs and store it in `/var/log` directory with `.log` extension. Promtail will read the logs from the log files and push them to Loki.

---

### Adding static labels to logs

- We can add static labels to our logs by updating Promtail configuration file. We have to add our lables under `labels` section of `scrape_configs` section.

```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: varlogs
          __path__: /var/log/*log
          environment: production # Static label
```
---

### Adding Dynamic labels to logs

- We can add dynamic labels to logs in Promtail configuration file. These logs will be fetched from the logs itself. To add dynamic labels, we have to use `pipeline_stages` section in `scrape_configs` section. Pipeline stages are used to modify the logs before sending them to Loki. There will be multiple stages in pipeline stages. Each stage will perform some modification and pass the logs to next stage.

```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: varlogs
          __path__: /var/log/*log
          label_name: # We also need to keep the label name here
    # To add Dynamic labels
    pipeline_stages:
      - logfmt:
          mapping:
            label_name:
      - labels:
           label_name:
```
---

### Visualizing logs in Grafana

- We can now easily visualize logs in Grafana by using Loki as a datasource. We can create a new dashboard and add a new panel of type `Logs` and then we can write a query to filter the logs based on the labels.

- If we want to visulaize our logs in a time series graphs, remember we need to use `rate` function.

Date of notes: 05/07/2024