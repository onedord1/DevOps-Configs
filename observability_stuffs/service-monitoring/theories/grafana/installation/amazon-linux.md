## Installing Grafana on Amazon Linux/RHEL/CentOS

### Steps:

- Run `sudo yum update` to update the package list.

- Use the below command to install Grafana.

```bash
sudo yum install -y https://dl.grafana.com/oss/release/grafana-11.1.0-1.aarch64.rpm
```

- Enable and start the Grafana service:

```bash
sudo systemctl enable grafana-server
sudo systemctl start grafana-server
```

- Check the status of the Grafana service:

```bash
sudo systemctl status grafana-server
```

- Now, we can access Grafana using the URL `http://localhost:3000`. The default username and password is `admin`. You can change the password after login.

Date of notes: 04/07/2024