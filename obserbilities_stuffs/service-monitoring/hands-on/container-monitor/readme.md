At first, build the docker image by running below command

`docker build --no-cache -t <registry>/<namespace>/<image_name>:<tag> .`

then push the image into registry

`docker push <your_image>`

then on the respective vms where docker container is supposed to be running run the container using below command

```bash
docker run \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:rw \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --publish=443:443 \
  --detach=true \
  --name=cadvisor \
  --privileged=true \
  <your_cadvisor_image>
```

## Setup Prometheus

First, create a file inside `/opt/prometheus/files_sd` with the name `docker_containers.yml` to add all containers to Prometheus, then add below lines

```bash
- labels:
    target_name: Local_QuickopsENT
  targets:
    - 172.17.19.172:443
```
A reference YML could be found on [this link](https://172.17.19.247/devops/config-yaml/-/blob/dev/aes-monitor/container-monitor/cAdvisor_setup/prometheus/docker_containers.yml).
Then refer to the `docker_containers.yml` in `prometheus.yaml` like below under `scrape_configs`

```bash
  scrape_configs:
    - job_name: 'docker-containers'
      file_sd_configs:
        - files:
            - '/opt/prometheus/files_sd/docker-containers.yml'
      scheme: https
      metrics_path: '/metrics'
      basic_auth:
        username: 'aesmonitor'
        password: 'UdnBf00R@z06' # add auth if needed
      tls_config:
        ca_file: '/opt/prometheus/ssl/node_exporter.crt'
        insecure_skip_verify: true
      relabel_configs:
        - source_labels: ['target_name']
          target_label: 'target_name'
```

Also, create a rules file inside `/opt/prometheus/rules` with the name `container_rules.yml` and refer to this file inside `prometheus.yml`. This will check if the container is down or up.

```bash
rule_files:
   - "rules/node_rules.yml"
   - "rules/container_rules.yml"
```

A complete [container_rules.yml](https://172.17.19.247/devops/config-yaml/-/blob/dev/aes-monitor/container-monitor/cAdvisor_setup/prometheus/container_rules.yml) would be found here.
## Setup Alertmanager

For alert setup, edit the `alertmanager.yml` and add these lines 

```bash
  routes:
    - match:
        alertname: 'DockerContainerDown'
      receiver: 'containeralert'
      group_wait: 30s
      group_interval: 10m
      repeat_interval: 1h
receivers:
  - name: 'containeralert'
    webhook_configs:
      - url: 'http://localhost:6000/dispatch'
        send_resolved: true

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance', 'target_name']
```

A complete reference would be found here [alertmanager.yml](https://172.17.19.247/devops/config-yaml/-/blob/dev/aes-monitor/container-monitor/cAdvisor_setup/alertmanager/alertmanager.yml).

For alert setup, you need a message template which can be found at [message.tmpl](https://172.17.19.247/devops/config-yaml/-/blob/dev/aes-monitor/container-monitor/cAdvisor_setup/calert/messege.tmpl).

Complete alert setup would be found here [alertmanager_setup](https://172.17.19.247/devops/config-yaml/-/tree/dev/aes-monitor/vm-monitor/alertmanager_setup/configs/calert).