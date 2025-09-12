## Defining Time Threshold for Alerts

- By default alerts have to fired for 1 minute to send the notification. If the alert is resolved before 1 minute, then the alert will not be sent. We can also change this value in the `alerts.yml` file.

```yaml
groups:
- name: example
  rules:
  - alert: HighRequestLatency
    expr: job:request_latency_seconds:mean5m{job="myjob"} > 0.5
    for: 10m # Duration for which the expression should be true.
    labels:
      severity: page
    annotations:
      summary: High request latency
```

If we don't define `for` parameter, then the `PromQL` expression has to be true for 1 minute to send the notification. If we define `for` parameter, then the `PromQL` expression has to be true for the duration we defined in the `for` parameter to send the notification.

Date of notes: 02/07/2024