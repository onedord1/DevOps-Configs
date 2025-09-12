## Installing Grafana on Ubuntu

### Steps:

- Run `sudo apt-get update` to update the package list.

- Use the below command to install Grafana on Ubuntu:

```bash
sudo apt-get install -y adduser libfontconfig1 musl
wget https://dl.grafana.com/oss/release/grafana_11.1.0_arm64.deb
sudo dpkg -i grafana_11.1.0_arm64.deb
```
The above command will also include Grafana Linux service for us to start Grafana.

- Reload the Daemon.

```bash
sudo systemctl daemon-reload
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