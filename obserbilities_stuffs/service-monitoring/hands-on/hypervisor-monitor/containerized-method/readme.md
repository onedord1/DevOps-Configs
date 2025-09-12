# 🚀 `prometheus-pve-exporter` for Proxmox VE

This setup collects metrics from your Proxmox VE cluster using a dedicated API token, and exposes them to Prometheus.

---

## 📂 Directory structure

```
/etc/prometheus/
├── pve.yml
```

---

## 📝 pve.yml configuration

Create the file `/etc/prometheus/pve.yml` with:

```yaml
default:
  user: prometheus@pve
  token_name: monitoring
  token_value: 1c5d96dc-1c51-45e5-8e2a-0d2fef32bd18 #token from -> 🔑 Proxmox user & token setup
  verify_ssl: false
```

> ✅ Ensure `token_name` is **only the token id** (`monitoring`), *not* `prometheus@pve!monitoring`.

---

## 🔑 Proxmox user & token setup

On your Proxmox node:

```bash
#Create user
useradd --no-create-home --system prometheus

# Create user if not already created
pveum user add prometheus@pve

#Remove if exists with same name
pveum user token remove prometheus@pve monitoring

# Create API token with privsep disabled
pveum user token add prometheus@pve monitoring --privsep 0

# Check if created
pveum user token list prometheus@pve

# Assign read-only auditor role
pveum aclmod / -user prometheus@pve -role PVEAuditor
pveum aclmod / -token 'prometheus@pve!monitoring' -role PVEAuditor
```

---

## 🚀 Docker Compose

Save as `docker-compose.yml`:

```yaml
version: "3.8"

services:
  prometheus-pve-exporter:
    image: prompve/prometheus-pve-exporter
    container_name: prometheus-pve-exporter
    ports:
      - "9221:9221"
    volumes:
      - /etc/prometheus/pve.yml:/etc/prometheus/pve.yml
    command: ["--config.file", "/etc/prometheus/pve.yml"]
    restart: unless-stopped
```

Then run:

```bash
docker compose up -d
```
## For Self-signed Certificate
Reference Dockercomposefile is [Compose](https://172.17.19.247/devops/config-yaml/-/blob/dev/aes-monitor/hypervisor-monitor/containerized-method/docker-compose.yml?ref_type=heads)

To set up SSL for your Prometheus instance, follow these steps:

1. **Create SSL Directory**  
   Make a folder named `ssl` inside `/etc/prometheus/`:
   ```bash
   mkdir -p /etc/prometheus/ssl
   ```

2. **Copy Certificate and Key**  
   Copy your certificate and key files into the `ssl` directory.

3. **Run Docker Compose**  
   Finally, run the following command to start your services:
   ```bash
   docker compose up -d
   ```  

---

## 🔍 Test it

Query directly:

```bash
curl -k "http://<your-proxmox-ip>:9221/pve?target=<your-proxmox-ip>&cluster=1&node=1"
```

You should see Prometheus metrics output.

---
