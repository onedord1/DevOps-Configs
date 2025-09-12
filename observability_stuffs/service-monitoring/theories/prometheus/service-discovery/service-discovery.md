## Service Discovery in Prometheus

### Why we need Service Discovery?

Normally we will run our workloads in servers. **If our applications is small and not going to get so many requests, we can run our application in small number of servers, we can easily add all the our servers to Prometheus configuration file. But if we our application is going to get so many requests, we are probably going to use cloud servers to run our workloads. But if we are in cloud environment, we will setup autoscaling groups to scale up or scale down our servers based on the load. So if our servers scale up or down based on loads, it's not possible to add and remove servers in `prometheus.yml` file manually.** This is the problem we have. In this case we can use service discovery to discover the servers automatically.

### How to configure Service Discovery in Prometheus?

We can configure service discovery in `prometheus.yml` file. There are many service discovery options available in Prometheus. Some of them are `file_sd_configs`, `kubernetes_sd_configs`, `ec2_sd_configs`, `consul_sd_configs`, `dns_sd_configs`, `gce_sd_configs`, `azure_sd_configs`, `openstack_sd_configs` and `dockerswarm_sd_configs`.

---

### Service Discovery for AWS EC2 and Lightsail

In Prometheus, there is two service discovery options available for AWS. They are `ec2_sd_configs` and `file_sd_configs`. We can use `ec2_sd_configs` for AWS EC2 instances and `file_sd_configs` for AWS Lightsail instances.

#### Properties of `ec2_sd_configs`

- `region`: Region of AWS EC2 instances.
- `access_key` and `secret_key`: AWS access key and secret key with enough permissions to discover EC2 instances.
- `port`: Port number for prometheus to scrape metrics from EC2 instances.
- `role_arn`: If our prometheus server is running in EC2 instance, we can use this property to assume a role to discover EC2 instances. We don't need to provide `access_key` and `secret_key` if we use `role_arn`.
- `refresh_interval`: By default, Prometheus will refresh the list of EC2 instances every 60 seconds. We can change the value of this using `refresh_interval` property.
- `filters`: We can use this property to filter the EC2 instances based on tags.
- `source_labels`: To add labels to our targets based on EC2 instance tags, We can also use `source_labels` property to discover EC2 instances based on some configurations of our EC2 instances like instance id, instance type, ami used, etc.

#### Options for `source_labels`

- `__meta_ec2_ami`: To discover EC2 instances based on AMI id.
- `__meta_ec2_instance_id`: Used to discover EC2 instances based on instance id.
- `__meta_ec2_instance_type`: Used to discover EC2 instances based on instance type.
- `__meta_ec2_private_dns_name`: Used to discover EC2 instances based on private DNS name.
- `__meta_ec2_public_dns_name`: Used to discover EC2 instances based on public DNS name.
- `__meta_ec2_public_ip`: To discover EC2 instances based on public IP address.
- `__meta_ec2_private_ip`: Used to discover EC2 instances based on private IP address.
- `__meta_ec2_availability_zone`: To discover EC2 instances based on availability zone.
- `__meta_ec2_availability_zone_id`: To discover EC2 instances based on availability zone id. But it need our role or secret key and access to have `ec2:DescribeAvailabilityZones` permission.
- `__meta_ec2_tag_<tagname>`: To discover EC2 instances based on tags. We can use this to discover EC2 instances based on tags. **For example**: `__meta_ec2_tag_Name` will discover EC2 instances based on Name tag.

#### Example of `ec2_sd_configs`:

```yaml
# Under scrape_configs

scrape_configs:
  - job_name: 'ec2'
    ec2_sd_configs:
      - region: 'us-east-1'
        access_key: 'AWS_ACCESS_KEY'
        secret_key: 'AWS_SECRET_KEY'
        port: 9100
        filters:
          - name: tag:Name
            values:
              - 'prometheus' # We can also use regex expressions here.
    relabel_configs:
      - source_labels: [__meta_ec2_tag_Name]
        target_label: instance # It will add a "instance" label to our targets.
      - source_labels: [__meta_ec2_instance_id]
        action: drop # It will drop the instances that have id like "i-0123...
        regex: 'i-0123.*'
      - source_labels: [__meta_ec2_public_ip]
        replacement: '${1}:9100' # It will replace target address with public ip address and port number.
        target_label: __address__
```

---

### File Based Service Discovery

We can use File based service discovery if there is no service discovery mechanism available for our environment. Example: If we have our servers in Alibaba Cloud, we don't have any service discovery mechanism available for Alibaba Cloud. In this case we can use file based service discovery.

#### How to use File Based Service Discovery?

- We have to create a file with `.json` or `.yml` extension. For linux, We can keep this file in `/etc/prometheus/file_sd/` directory. In Mac OS and Windows, We can keep this file in directory next to `prometheus.yml` file. In this file, we have to add targets or servers or node exporters. that we want to scrape metrics from.

```yml
- targets:
  - 'localhost:9100'
    labels:
        group: 'production'
        env: 'prod'
```

- Now we need to Update `prometheus.yml` file to use file based service discovery.

```yml
scrape_configs:
  - job_name: 'file_sd'
    file_sd_configs:
      - files:
        - '/etc/prometheus/file_sd/*.yml' # Using *, so that in future we just keep adding our target files in the `/etc/prometheus/file_sd/` directory.
```

In order to apply the changes, we need to restart the Prometheus server.

Date of notes: 03/07/2024