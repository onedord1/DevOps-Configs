## Push Gateway in Prometheus

### Why we need Push Gateway?

If we are run our workloads in cloud servers, we are probably going to use autoscaling groups to scale up or down our servers based on the load. And also mostly we are going to have a Load Balancer in front of our servers. So in this case our Load servers only going to have a private IP address and our load balancer will have public IP address. Now if we try to scrape metrics from load balancer, we are not going to get metrics of same servers because load balancers usually distribute requests based on Round Robin algorithm. So in this case we can use Push Gateway to make our application in the servers to push metrics to Push Gateway and then Prometheus can scrape metrics from Push Gateway.<br>

And also if we are using serverless functions to run our workloads, Usually serverless functions don't have any IP address or DNS name. So it's not possible to use prometheus to scrape metrics from serverless functions. In this case we can use Push Gateway to make our serverless functions to push metrics to Push Gateway and then Prometheus can scrape metrics from Push Gateway.<br>

We have to code our applications and serverless functions to push metrics to Push Gateway. We can use Prometheus client libraries to push metrics to Push Gateway.


### Installing Push Gateway

1. **For Windows and Mac:**

- Download the latest version of Push Gateway from [here](https://prometheus.io/download/#pushgateway). Select the zip file for Windows and tar file for Mac.
- Extract the downloaded file.
- Go to the extracted folder.
- Run the following command to start Push Gateway:

```bash
./pushgateway
```
- We can use `--help` flag to see all the available options.
- By default, Push Gateway will run on port 9091. We can change the port using `--web.listen-address` flag.

2. **For Linux:**

- Download the latest package of Push Gateway from [here](https://prometheus.io/download/#pushgateway) for Linux.
```bash
wget https://github.com/prometheus/pushgateway/releases/download/v1.9.0/pushgateway-1.9.0.linux-amd64.tar.gz
```
- Extract the downloaded file.
```bash
tar -xvf pushgateway-1.9.0.linux-amd64.tar.gz
```
- Go to the extracted folder.
```bash
cd pushgateway-1.9.0.linux-amd64
```
- If you list the files, you will see `pushgateway` binary file.

- We can run Push Gateway as Process. But the better option is to run Push Gateway as a service. We can use `systemd` to run Push Gateway as a service.

- Create a file named `pushgateway.service` in `/etc/systemd/system/` directory.
```bash
sudo nano /etc/systemd/system/pushgateway.service

# Add the following content to the file.
[Unit]
Description=Prometheus Pushgateway
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/pushgateway

[Install]
WantedBy=multi-user.target
```
- Now we need to move the `pushgateway` binary file to `/usr/local/bin/` directory.
```bash
sudo mv pushgateway /usr/local/bin/
```

- Giving `promehteus` user permissions to `pushgateway` binary file. If you don't have `prometheus` user, you can create it using the following command.
```bash
sudo groupadd --system prometheus
sudo useradd -s /sbin/nologin --system -g prometheus prometheus 

# If you already have `prometheus` user, you can use the following command.
sudo chown prometheus:prometheus /usr/local/bin/pushgateway
```

- Reload the `systemd` daemon.
```bash
sudo systemctl daemon-reload
```

- Start the Push Gateway service.
```bash
sudo systemctl start pushgateway
```

- Enable the Push Gateway service to start on boot.
```bash
sudo systemctl enable pushgateway
```

- Check the status of Push Gateway service.
```bash
sudo systemctl status pushgateway
```

Now we can access our Push Gateway metrics using `http://localhost:9091/metrics` in the browser.<br>

### Updating Prometheus Configuration to Scrape Metrics from Push Gateway

We have to add the following configuration to our `prometheus.yml` file to scrape metrics from Push Gateway.

```yaml
scrape_configs:
  - job_name: 'pushgateway'
    static_configs:
      - targets: ['localhost:9091']
```

### Sending Metrics to Push Gateway

#### Example of sending metrics to Push Gateway using Python

- In order to push metrics to Push Gateway, we need to use prometheus_client library. We can install it using the below command:
```bash
pip install prometheus_client
```

- Sample Python code to push metrics to Push Gateway:
```python
# In order to push metrics to Push Gateway, we need to use push_to_gateway, CollectorRegistry Classes from prometheus_client library.
from prometheus_client import CollectorRegistry, Gauge, push_to_gateway 

# By default all the metrics will be pushed to default registry. We need to make our push gateway to push metrics to some new registry in order to avoid conflicts with other metrics names.
registry = CollectorRegistry()

# Create a Gauge object to create Metrics
g = Gauge('my_gauge', 'This is my gauge', registry=registry)

while True:
    # Set the value of the Gauge
    g.set(10)

    # Push the metrics to Push Gateway
    push_to_gateway('localhost:9091', job='my_job', registry=registry)
```

Date of notes: 03/07/2024