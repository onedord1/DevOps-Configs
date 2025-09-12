
````markdown
# 📧 Alertmanager Email Setup Guide

This guide details how to configure Alertmanager to send email alerts using SMTP, based on the provided `alertmanager.yml`.

---

## 🛠 Alertmanager Configuration

```yaml
global:
  resolve_timeout: 5m
  # SMTP defaults
  smtp_smarthost: 'mail.quickops.io:587'
  smtp_from: 'notification@quickops.io'
  smtp_auth_username: 'notification@quickops.io'
  smtp_auth_password: '<SMTP_PASSWORD>'
  smtp_require_tls: true

route:
  receiver: 'Mail Alert'
  repeat_interval: 10m
  group_wait: 15s
  group_interval: 15s
  routes:
    - match:
        severity: "critical"
      receiver: 'Mail Alert'
      repeat_interval: 30m
      routes:
        - receiver: 'Mail Alert'
          repeat_interval: 1h

receivers:
  - name: 'Mail Alert'
    email_configs:
      - to: 'kader.khan@anwargroup.com, jasim.alam@anwargroup.com'
        send_resolved: true
        headers:
          Subject: 'Prometheus Mail Alerts'

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance', 'target_name']
````

---

## 🔎 How It Works

* **Global SMTP Settings**
  Sets defaults for email delivery (`smtp_smarthost`, `from`, authentication, TLS). These are inherited by receivers unless overridden ([stackoverflow.com][1], [prometheus.io][2], [prometheus.io][3]).

* **Routing**

  * Primary receiver: `Mail Alert`.
  * Critical alerts repeat every **30 minutes**, others every **1 hour**.
  * General repeat interval is **10 minutes**.

* **Email Receiver**

  * Sends to multiple addresses (`to` field).
  * `send_resolved: true` ensures a notification is sent when an alert clears (recovery notification).

* **Inhibition Rules**

  * Suppresses warnings if a related critical alert is active, avoiding duplicate notifications.

---

## ✅ Configuration Steps

1. **Store SMTP credentials securely**
   Replace `<SMTP_PASSWORD>` with your real password or use an environment variable.

2. **Save this file as** `alertmanager.yml` (overwrite or merge with existing).

3. **Reload Alertmanager**

   ```bash
   systemctl reload alertmanager
   # or via HTTP:
   curl -X POST http://<alertmanager-host>:9093/-/reload
   ```

4. **Test an alert**
   Trigger a test alert and ensure emails are received (both firing and resolved messages).

---

## ✉️ Customizing Subject and Content

To create dynamic subjects like `"[FIRING] CPU usage high on server-1"`, modify the alert rule:

```yaml
annotations:
  subject: "[{{ .Status | toUpper }}] {{ .CommonLabels.alertname }} on {{ .CommonLabels.target_name }}"
```

Then use in the email config:

```yaml
headers:
  Subject: '{{ .CommonLabels.subject }}'
```

---

## 📜 References

* Alertmanager SMTP email setup ([blog.devops.dev][4], [groups.google.com][5], [blog.devops.dev][6], [prometheus.io][2])
* `send_resolved` option for email configs&#x20;

---