# Harbor Private Registry Setup Guide

**Author**: Jasim Alam  
**Version**: 1.0.0  
**Last Updated**: May 24, 2025  

---

## Overview

This guide outlines the steps to install and configure a private Harbor container registry secured with a Let's Encrypt SSL certificate.

---

## Server Information

- **Domain**: `registry.aes-core.com`
- **IP Address**: `172.17.17.240` `115.127.156.173`
- **Resources**:
  - vCPU: 2
  - RAM: 4 GB
  - Disk: 40 GB

---

## 1. Install Docker

```bash
apt install ca-certificates curl gnupg lsb-release -y

mkdir -p /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update -y
apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y

systemctl status docker
```

---

## 2. SSL Certificate via Let's Encrypt (Using acme.sh)

```bash
git clone https://github.com/acmesh-official/acme.sh.git
cd /root/acme.sh/

./acme.sh --set-default-ca --server letsencrypt
./acme.sh --register-account -m <your-email@example.com>

# Issue SSL certificate using DigitalOcean DNS
export DO_API_KEY="your_digitalocean_api_key"

./acme.sh --issue --dns dns_dgon -d registry.cloudaes.com

# Copy certs to Harbor SSL directory
mkdir -p /etc/ssl/harbor/
cp /root/.acme.sh/registry.cloudaes.com_ecc/fullchain.cer /etc/ssl/harbor/registry.cloudaes.com.crt
cp /root/.acme.sh/registry.cloudaes.com_ecc/registry.cloudaes.com.key /etc/ssl/harbor/registry.cloudaes.com.key
```

---

## 3. Install Harbor

```bash
cd /opt

wget https://github.com/goharbor/harbor/releases/download/v2.13.0/harbor-online-installer-v2.13.0.tgz

tar -xvf harbor-online-installer-v2.13.0.tgz
cd harbor

cp harbor.yml.tmpl harbor.yml
```

---

## 4. Configure Harbor

Edit `harbor.yml` to define key settings:

```yaml
hostname: registry.cloudaes.com

https:
  port: 443
  certificate: /etc/ssl/harbor/registry.cloudaes.com.crt
  private_key: /etc/ssl/harbor/registry.cloudaes.com.key
```

---

## 5. Deploy Harbor


use the installer:

```bash
./install.sh --with-trivy
```

modify compose not to use AES IP block 172.16.X

```
# cat /etc/docker/daemon.json 
{
  "bip": "192.168.100.1/24"
}
systemctl restart docker
```


```
docker network rm harbor_harbor
docker network create --subnet=192.168.200.0/24 harbor
sed -i 's/^\(\s*external:\s*\)false/\1true/' /opt/docker-compose.yml
cd /opt/harbor
docker compose down
docker compose up -d
```

---

## 6. Docker Login to Harbor

Once Harbor is running:

```bash
docker login registry.cloudaes.com
```

Provide credentials configured during setup.

---

## 7. Automatic SSL Certificate Renewal

cron entry:

```bash
0 3 1 * * /usr/local/bin/renew-harbor-cert.sh >> /var/log/harbor_cert_renew.log 2>&1
```

## 8. backup job

cron job

```bash
10 0 * * * /opt/harbor-backup.sh >> /var/log/harbor_backup.log 2>&1
```

log rotate 

```
# cat /etc/logrotate.d/harbor_backup 
/var/log/harbor_backup.log {
    monthly
    rotate 1
    missingok
    notifempty
    compress
    delaycompress
    copytruncate
}
```

## 9. backup restore

```
./harbor-restore.sh /opt/harbor/backups/harbor_backup_20250528_124542.tar.gz
or
./harbor-restore.sh s3://harbor_backup_20250528_124542.tar.gz
```