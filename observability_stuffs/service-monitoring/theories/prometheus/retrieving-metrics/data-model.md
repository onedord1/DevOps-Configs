## Data Model of Prometheus

Prometheus stores data in a time series format which for every metric, there will be a linux timestamp attached to it. Each metric is identified by a metric name and a set of key-value pairs called labels. The labels are optional and can be used to filter and aggregate the metrics.

**Example of a metric:**

```
http_requests_total{method="GET", handler="/api/v1/users", status="200"}
```

Date of notes: 01/07/2024