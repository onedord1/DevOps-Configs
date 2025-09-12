# 📦 Postgres Exporter Setup (kube‑prometheus‑stack)

This guide demonstrates how to deploy the Postgres Exporter with Prometheus Operator (via `kube‑prometheus‑stack`) in a Kubernetes cluster.

## 🔁 Things that usages here
- Prometheus Operator installed via **kube‑prometheus‑stack**

---

## ⚙️ Deployment Template

Templated manifest—replace placeholders `{{ ... }}` before applying.

### 1. Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgresdb-exporter
  namespace: {{ TARGET_NAMESPACE }}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgresdb-exporter
  template:
    metadata:
      labels:
        app: postgresdb-exporter
    spec:
      containers:
        - name: postgresdb-exporter
          image: quay.io/prometheuscommunity/postgres-exporter
          ports:
            - containerPort: 9187
          env:
            - name: DATA_SOURCE_NAME
              value: "postgres://{{ DB_USER }}:{{ DB_PASSWORD }}@{{ DATABASE_SERVICE }}:{{ DB_PORT }}/{{ DB_NAME }}?sslmode=disable"
```

### 2. Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgresdb-exporter
  namespace: {{ TARGET_NAMESPACE }}
  labels:
    app: postgresdb-exporter
spec:
  type: ClusterIP
  ports:
    - name: postgresdb-exporter-port
      protocol: TCP
      port: 9187
      targetPort: 9187
  selector:
    app: postgresdb-exporter
```

### 3. ServiceMonitor

## 🔍 Step 1: Check Prometheus CRD's selector

```bash
kubectl -n aescloud-engine get prometheus aescontroller-monitoring-o-prometheus -o yaml \
  | grep -A4 serviceMonitorSelector
```
This shloud output like below:

```yaml
serviceMonitorSelector:
  matchLabels:
    release: aescontroller-monitoring-operator
```
This means Prometheus will only pick up ServiceMonitors labeled release: aescontroller-monitoring-operator.

## 📌 Step 2: Label your ServiceMonitor accordingly

Since Prometheus is filtering ServiceMonitors by that release label, your ServiceMonitor YAML needs:

```yaml
metadata:
  labels:
    release: aescontroller-monitoring-operator
```

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: postgresdb-exporter-sm
  namespace: {{ TARGET_NAMESPACE }}
  labels:
    release: {{ PROM_OPERATOR_RELEASE }} #aescontroller-monitoring-operator
spec:
  selector:
    matchLabels:
      app: postgresdb-exporter
  namespaceSelector:
    matchNames:
      - {{ EXPORTER_NAMESPACE }}
  endpoints:
    - port: postgresdb-exporter-port
      path: /metrics
      interval: 30s
```

---

## 🔍 Verification Steps

🎯 Confirm Service exists and is correctly labeled:

```bash
kubectl -n {{ TARGET_NAMESPACE }} get svc -l app=postgresdb-exporter
```

✅ Then port‑forward Prometheus and check targets:

```bash
kubectl -n {{ PROM_OPERATOR_NAMESPACE }} port-forward svc/{{ PROMETH_PROM_RELEASE_NAME }}-prometheus 9090:9090
# Open in browser: http://localhost:9090/targets
```

Look for:

```
{{ EXPORTER_NAMESPACE }}/postgresdb-exporter:9187 (via postgresdb-exporter-sm) – UP
```

---

## 🧠 How It Works

1. Exporter exposes metrics on port 9187.
2. Service makes the exporter reachable within the cluster.
3. ServiceMonitor tells Prometheus how to scrape the metrics.
4. kube‑prometheus‑stack automatically discovers the ServiceMonitor and includes it in the Prometheus scrape config.

---

## Reference

[https://github.com/prometheus-community/postgres_exporter#running-multiple-instances-on-the-same-machine](https://github.com/prometheus-community/postgres_exporter#running-multiple-instances-on-the-same-machine)
