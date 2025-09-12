## Data Types in Prometheus

Prometheus uses `PromQL` (Prometheus Query Language) to query the metrics. To query using `PromQL`, we need to understand the data types in Prometheus.

### Data Types

1. **Scalar**: It includes Float and Integer values. For example, `http_requests_total` will return the value of `http_requests_total` at the current time.

2. **Instant Vector**: It is a set of time series containing a single sample for each time series, all will share the same timestamp. For example, `http_requests_total{method="GET", handler="/api/v1/users", status="200"}` will return the value of `http_requests_total` at the current time.

3. **Range Vector**: It is a set of time series containing a range of data points over time. For example, `http_requests_total{method="GET", handler="/api/v1/users", status="200"}[5m]` will return the value of `http_requests_total` for the last 5 minutes.

4. **String**: It is a string value. For example: `http_requests_total{method="GET", handler="/api/v1/users", status="200"}` here `method`, `handler`, and `status` are having string values.

Date of notes: 01/07/2024