## Adding more Context to Alerts

### Why we need to add more context to alerts?

Let's we are working in a company. We are defining alerts in `alerts.yaml` file. If someone else is going to read the alerts file, they will not know what the alert is about. They will not know whethet thsi alert is important or not, which team is responsible for this alert, what is the impact of this alert etc. So to avoid this confusion, we need to add more context to the alerts.<br>

We can add more context to alerts by using two parameters:

1. `labels`: Used to identify the alert.
2. `annotations`: Used to provide more information about the alert like summary, description etc.

### How to add more context to alerts?

```yaml
groups:
- name: example
  rules:
  - alert: HighRequestLatency
    expr: job:request_latency_seconds:mean5m{job="myjob"} > 0.5
    for: 10m
    labels:
      severity: page
      team: frontend # Team responsible for this alert
      impact: high # Impact of this alert
    annotations:
      summary: High request latency # Short description of the alert
      description: The request latency is high. It's impacting the user experience. The frontend team has to look into this issue. # Detailed description of the alert
```

### Template for adding more context to alerts

We can also use templates in `labels` and `annotations` to add more context to alerts. Prometheus provides some default templates. We can use them to add more context to alerts.

- `{{ $labels.<label_name> }}`: Used to add the label value to the alert. For example, `{{ $labels.instance }}` will add the value of the `instance` label to the alert. We can also use `{{ $labels }}` to add all the labels to the alert.
- `{{ $value }}`: Used to add the value of the alert to the alert.

```yaml
groups:
- name: example
  rules:
  - alert: HighRequestLatency
    expr: job:request_latency_seconds:mean5m{job="myjob"} > 0.5
    for: 10m
    labels:
      severity: page
      team: frontend
      impact: high
    annotations:
      summary: High request latency in {{ $labels.instance }}
        description: The request latency is high in {{ $labels.instance }}. It's impacting the user experience. The frontend team has to look into this issue. The value of the alert is {{ $value }}.
```

- `{{ $labels.instance }}`: Will return the value of the label called `instance`.
- `{{ $value }}`: Will return the value of the alert. In the above case it is value of `job:request_latency_seconds:mean5m{job="myjob"}` which are greater than `0.5`.

Date of notes: 02/07/2024