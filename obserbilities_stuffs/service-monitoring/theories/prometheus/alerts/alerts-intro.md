## Alerts Introduction

### Why alerts are needed?

Let's say we have a website running on a server. We configured prometheus to monitor the website. Prometheus is collecting the metrics like CPU, Memory, Disk, Network, I/O etc.  Now let's say our website is down. We don't know that our website is down. And after some our customers are calling us and saying that they are not able to access the website. Now It's not a ideal approach. Because if our customers are not satisfied with our service, they will move to another service. So we need to know that our website is down before our customers know. In this case we need to setup some alerts. So that we will get notified when our website is down.

### Configuring Alerts Thresholds values

We don't have to keep our threshold values very low. Because if we keep the threshold values very low, we will get lot of alerts like if our website is slow due to high traffic, we will get alert. But it can be auto resolved. So we need to keep the threshold values in perfect range. So that we will get alerts only when it's necessary.

### Defining Alerts

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

### How Alerts are sent?

- **Normally in prometheus if our alert definition is true, then the alert will be fired. The alerts will be raised in Prometheus UI only. So to send it as a notification, we need one prometheus component called `Alertmanager`**. When a alert is fired, Alertmanager get the signal from Prometheus and it will convert the alerts from Prometheus format to the notification format. And it will send the alerts to the notification channels like Email, Slack, PagerDuty etc.

- Also it will deduplicate the alerts. If we have cluster of prometheus servers and they are monitoring the same target. And if the target is down, then all the prometheus servers will raise the alert. Alertmanager will deduplicate the alerts and it will send only one alert.

Date of notes: 02/07/2024