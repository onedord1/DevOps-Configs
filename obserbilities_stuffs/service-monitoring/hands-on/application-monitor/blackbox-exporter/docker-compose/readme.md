# 🚀 Blackbox Exporter with Prometheus — Docker Compose Setup

## 1. Prerequisites

- Docker & Docker Compose installed  
- `openssl`, `htpasswd` or `mkpasswd` for bcrypt  
- `git`, `curl` for testing

---

## 2. Generate TLS Certificates

```bash
# Create CA
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -sha256 \
  -days 3650 -subj "/CN=MyCA"

# Create server cert signed by your CA
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr \
  -subj "/CN=blackbox"
openssl x509 -req -in server.csr -CA ca.key -CAcreateserial \
  -out server.crt -days 365 -sha256
```

Files created: `ca.key`, `ca.crt`, `server.key`, `server.crt`.

---

## 3. Generate Basic Auth Hash

Choose one:

### Option A: `htpasswd`

```bash
apt-get install apache2-utils
htpasswd -bnBC 12 "" "TdxBfh1R^z91" | tr -d ':\n'
```

### Option B: `mkpasswd`

```bash
apt-get install whois
echo -n "LdnBfjjo@l06" | mkpasswd -m bcrypt --stdin
```

Make sure the output is a bcrypt hash (\~60 chars, starts with `$2a$/$2b$/$2y$`).

---

## 4. Setup Directory Structure

```
.
├── certs/
│   ├── ca.crt
│   ├── server.crt
│   └── server.key
├── blackbox/
│   ├── blackbox.yml
│   └── web.config.yml
└── docker-compose.yml
```

---

## 5. `blackbox/blackbox.yml`

```yaml
modules:
  https_health:
    prober: http
    http:
      preferred_ip_protocol: "ip4"
      tls_config:
        ca_file: /certs/ca.crt
        insecure_skip_verify: false
      method: GET
      valid_http_versions: ["HTTP/1.1", "HTTP/2"]
      fail_if_not_ssl: true
      fail_if_body_not_matches_regexp:
        - ".*OK.*"
```

---

## 6. `blackbox/web.config.yml`

```yaml
tls_server_config:
  cert_file: /certs/server.crt
  key_file: /certs/server.key

basic_auth_users:
  aesmonitor: '$2y$12$<YOUR_BCRYPT_HASH>'
```

---

## 7. `docker-compose.yml`

```yaml
services:
  blackbox:
    image: prom/blackbox-exporter:latest
    container_name: blackbox
    restart: unless-stopped
    ports:
      - "9115:9115"
    volumes:
      - ./certs:/certs:ro
      - ./blackbox/blackbox.yml:/etc/blackbox_exporter/config.yml:ro
      - ./blackbox/web.config.yml:/etc/blackbox_exporter/web.config.yml:ro
    command:
      - '--config.file=/etc/blackbox_exporter/config.yml'
      - '--web.config.file=/etc/blackbox_exporter/web.config.yml'
```

---

## 8. `prometheus.yml` Scrape Config

```yaml
scrape_configs:
  - job_name: 'blackbox'
    scheme: https
    metrics_path: /probe
    basic_auth:
      username: 'aesmonitor'
      password: 'MlqLf86u@h19'
    tls_config:
      ca_file: '/opt/prometheus/ssl/ca.crt'
      insecure_skip_verify: true
    params:
      module: [https_health]
    file_sd_configs:
      - files:
          - '/opt/prometheus/files_sd/blackbox_targets.yml'
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: localhost:9115
```

---

## 9. `files_sd/blackbox_targets.yml`

```yaml
- labels:
    target_name: sonarqube
  targets:
    - https://sonarqube.quickops.io/health

- labels:
    target_name: dev
  targets:
    - https://dev.quickops.io/health
```

---

## 🔁 10. Run & Verify

```bash
docker-compose up -d
# Reload Prometheus (e.g., kill -HUP or POST to /-/reload)

curl -k -u aesmonitor:Hdhhf0k0r@d06 \
 "https://localhost:9115/probe?target=https://sonarqube.quickops.io/health&module=https_health"
```

✅ Should return `probe_success=1`

---

