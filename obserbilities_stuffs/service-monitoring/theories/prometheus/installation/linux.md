## Installing Prometheus in Linux(Ubuntu)

1. Go to the [Prometheus download page](https://prometheus.io/download/).

2. Use the Operating System filter to select Linux. Also select the Architecture filter to select the architecture as per your system.

3. Right click on the download link and copy the link address.

4. Open the terminal and run the below command to download the Prometheus tar file.

```bash
wget https://github.com/prometheus/prometheus/releases/download/v2.53.0/prometheus-2.53.0.linux-amd64.tar.gz
```

5. Now we need to create a user and group for Prometheus. Run the below command to create a user and group.

```bash
sudo groupadd --system prometheus
sudo useradd -s /sbin/nologin --system -g prometheus prometheus
```
6. Create a  directories for Prometheus in `/var/lib` and `/etc` locations
```bash
sudo mkdir /var/lib/prometheus
sudo mkdir /etc/prometheus
```

7. In linux we need to create directories for rules so that when we create rules in user interface, it will be stored in the below location.

```bash
sudo mkdir /etc/prometheus/rules
sudo mkdir /etc/prometheus/rules.s
sudo mkdir /etc/prometheus/file_sd
```

8. Let's `unzip` the downloaded tar file now

```bash
sudo tar xvf prometheus-2.53.0.linux-amd64.tar.gz
```

9. Change the directory to the extracted directory.

```bash
cd prometheus-2.53.0.linux-amd64
```

10. If we list the files in the directory, we can see the `prometheus` binary file.

```bash
ls
```
It will have some files and directories like below.

```
LICENSE
NOTICE
console_libraries
consoles
prometheus
prometheus.yml
promtool 
```
Here `console_libraries` and `consoles` are the binaries for the Prometheus UI, `prometheus` is the Prometheus binary file, `prometheus.yml` is the configuration file for Prometheus.

11. Now we need to move the Prometheus binary file `prometheus` and `promtool` to `/usr/local/bin` directory.

```bash
sudo mv prometheus promtool /usr/local/bin
```

12. Move the `prometheus.yml`, `console_libraries` and `consoles` to `/etc/prometheus` directory.
```bash
sudo mv prometheus.yml /etc/prometheus/
sudo mv console_libraries consoles /etc/prometheus/
```

13. Then create a service file for Prometheus in `/etc/systemd/system/` directory. It will start the Prometheus service whenever the system boots.

```bash
sudo nano /etc/systemd/system/prometheus.service
```

**prometheus.service**

```service
[Unit]
Description=Prometheus
Documentation=https://prometheus.io/docs/introduction/overview/
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.listen-address=0.0.0.0:9090 \
  --web.external-url=

SyslogIdentifier=prometheus
Restart=always

[Install]
WantedBy=multi-user.target
```

14. Make the `prometheus` user as the owner of all the directories we created.

```bash
sudo chown -R prometheus:prometheus /etc/prometheus/
sudo chown -R prometheus:prometheus /etc/prometheus/* # For folders under /etc/prometheus directory
sudo chown -R prometheus:prometheus /var/lib/prometheus 
```

Now grant access our prometheus user to the folders we created.

```bash
sudo chmod -R 775 /etc/prometheus/
sudo chmod -R 775 /etc/prometheus/* # For folders under /etc/prometheus directory
sudo chmod -R 775 /var/lib/prometheus
```

15. Reload the systemd daemon and start the Prometheus service.

```bash
sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus
```

16. Check the status of the Prometheus service.

```bash
sudo systemctl status prometheus
```

17. Now we can access the Prometheus UI by going to `http://localhost:9090` in the browser.

Date of notes: 01/07/2024