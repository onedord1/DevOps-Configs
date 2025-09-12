## Setup MySQL DB Exporter

First, create a `.mysqlexp.cnf` file, which is required for running the exporter container. This file should contain the database user credentials with access to the MySQL instance you wish to monitor.

Add the following lines to the `.mysqlexp.cnf` file:

```cnf
[client]
user=dbuser
password=securepassword
```

Then, start the exporter using Docker Compose:

```bash
docker-compose up -d
```

Access the exporter in your browser:

```
localhost:9104
```

## Prometheus Setup

To integrate with Prometheus, create a `mysqldb.yml` file in the `files_sd` directory (or your configured service discovery directory) and add the target MySQL DB instance details as follows:

```yaml
- labels:
    target_name: Local_QuickOps_MysqlDB
  targets:
    - 172.17.19.172:9104
```

Save the `mysqldb.yml` file and then edit the `prometheus.yml` configuration file to add a new job for the MySQL exporter:

```yaml
  - job_name: 'mysqldb'
    file_sd_configs:
      - files:
          - '/opt/prometheus/files_sd/local_mysqldb.yml'
    scheme: http
    metrics_path: '/metrics'
    basic_auth:
      username: 'aesmonitor'   # if authentication is needed
      password: 'UdnBf00R@z06'
    tls_config:
      ca_file: '/opt/prometheus/ssl/node_exporter.crt' # self-signed certificate
      insecure_skip_verify: true
    relabel_configs:
      - source_labels: ['target_name']
        target_label: 'target_name'
```

After modifying the `prometheus.yml` file, restart the Prometheus service:

```bash
sudo systemctl restart prometheus
```

## Verification

Verify the setup by browsing to the Prometheus targets page in your browser:

```
localhost:9090/targets
```

You should see a section for `mysqldb` indicating the status of the exporter.

## Reference

[https://github.com/prometheus/mysqld_exporter](https://github.com/prometheus/mysqld_exporter)
