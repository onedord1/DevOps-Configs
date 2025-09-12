```markdown
# Prometheus Remote Write Setup for Multi-Cluster Monitoring

This guide describes how to configure Prometheus instances running in multiple Kubernetes clusters to **remote write** their metrics to a centralized Prometheus server.

## 📌 Objective

Enable each Prometheus instance (running in its own cluster) to forward metrics to a central Prometheus endpoint using `remoteWrite`.

---

## 🔧 Central Prometheus Endpoint

All cluster Prometheus instances will push their metrics to:

```

[https://172.17.17.239/api/v1/write](https://172.17.17.239/api/v1/write) # change this url with yours

````

> ✅ TLS is enabled but certificate verification is skipped using `insecureSkipVerify: true`.

---

## 🔐 Step 1: Create Authentication Secret

Each Prometheus instance uses **basic authentication** to send metrics to the central Prometheus.

Run the following command in the namespace where Prometheus is deployed (example: `aescloud-engine`):

```bash
kubectl create secret generic central-auth \
  -n aescloud-engine \
  --from-literal=username=aesadmin \
  --from-literal=password='@es2025'
````

This creates a secret containing the basic auth credentials used in remote write.

---

## 🛠️ Step 2: Patch Prometheus to Enable Remote Write

Use `kubectl patch` to inject the remote write configuration into the Prometheus custom resource.

Replace `aescontroller-monitoring-o-prometheus` with your Prometheus instance name, and `dev-cluster-2` with your cluster identifier.

```bash
kubectl -n aescloud-engine patch prometheus aescontroller-monitoring-o-prometheus \
  --type merge \
  -p '{
    "spec": {
      "remoteWrite": [
        {
          "url": "https://172.17.17.239/api/v1/write",
          "basicAuth": {
            "username": {
              "name": "central-auth",
              "key": "username"
            },
            "password": {
              "name": "central-auth",
              "key": "password"
            }
          },
          "tlsConfig": {
            "insecureSkipVerify": true
          }
        }
      ],
      "externalLabels": {
        "cluster": "dev-cluster-2"
      }
    }
  }'
```

### 📌 Notes:

* `remoteWrite`: Points Prometheus to the central write endpoint.
* `basicAuth`: Uses credentials from the `central-auth` secret.
* `externalLabels`: Tags metrics with the `cluster` name for identification at the central server.

---

## ✅ Step 3: Verify Configuration

Once patched, confirm that the central Prometheus is receiving data using the `externalLabels.cluster` label:

In the central Prometheus UI (or via query):

```promQL
up{cluster="dev-cluster-2"}
```

You should see results for all targets sending data from the `dev-cluster-2`.

---

## 📁 Repeat for Other Clusters

For each cluster:

1. Adjust the namespace and Prometheus name.
2. Use a unique cluster name for `externalLabels.cluster`.

---

## 📦 Optional Automation

This process can be scripted or integrated into GitOps pipelines (e.g., ArgoCD, Flux) for automatic propagation across clusters.

---

## 🔐 Security Consideration

* Ensure `@es2025` is securely stored and rotated periodically.
* Use proper TLS certificates in production instead of `insecureSkipVerify: true`.

---
```
