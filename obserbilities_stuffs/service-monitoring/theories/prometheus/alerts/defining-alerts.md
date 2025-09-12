## Defining Alerts

Alerts in Prometheus are defined in `.yml` file. 

```yml
groups:
- name: example
  rules:
  - alert: HighRequestLatency # Type of Rule
    expr: job:request_latency_seconds:mean5m{job="myjob"} > 0.5
    for: 10m
    labels:
      severity: page
    annotations:
      summary: High request latency
```

- `groups`: It will contain the list of groups. Each group will contain the list of rules.
- `name`: Name of the group.
- `rules`: Contain list of rules. Each rule contains an alert.
- `alert`: Name of the alert.
- `expr`: It's the `PromQL` expression. If the expression is true, then the alert will be fired.
- `for`: Duration for which the expression should be true.
- `labels`: It's a list of labels. Used to identify the alert. 
- `annotations`: Contains list of annotations. Used to provide more information about the alert like summary, description etc.

The `PromQL` expression is the key part of the alert. It will be constantly evaluated by Prometheus. If the expression is true, then the alert will be fired.<br>

We have to keep the `.yml` file in the prometheus server. For `Linux` it will be in `/etc/prometheus/rules/` directory. For `Windows` and `MacOS` we can create one rules directory next to the `prometheus.yml` file
and keep all the alert `.yml` files in that directory.

### Updating `prometheus.yml` file

Once we have defined the alerts in `.yml` file, we have to update the `prometheus.yml` file to include the alert `.yml` file.

```yml
# Under the `scrape_configs` section

rule_files:
  - "rules/alerts.yml" # Relative path to the alert .yml file
```

Date of notes: 02/07/2024