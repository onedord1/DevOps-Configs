## Inhibiting Alerts using Alertmanager

### Why we need to inhibit alerts?

Let's say we have a website running on a server. We configured prometheus to monitor both the server and website. And we defined two alerts in the `alerts.yml` file. One alert is for server and another alert is for website. Now let's say the server is down. In this case the server alert will be fired. And the website alert will also be fired. But we don't need the website alert to be fired. Because the website is down because the server is down. So we need to inhibit the website alert when the server alert is fired. In this case we need to inhibit the alerts.

### How to inhibit alerts?

Let's define two alerts in the `alerts.yml` file. One alert is for server and another alert is for website.

```yaml
groups:
- name: example
  rules:
  - alert: ServerDown
    expr: up == 0
    for: 1m
    labels:
      severity: page
      purpose: server
    annotations:
      summary: Server is down

  - alert: WebsiteDown
    expr: website_up == 0
    for: 1m
    labels:
      severity: page
      purpose: website
    annotations:
      summary: Website is down
```

Now we have to define the inhibition rules in the `alertmanager.yml` file.

```yaml
inhibit_rules:
  - source_match:
      purpose: 'server'
    target_match:
      purpose: 'website'
    equal: ['severity']
```

- `source_match`: Match the alert which is firing. And we need to inhibit other alert based on this alert.
- `target_match`: Match the alert which we need to inhibit.
- `equal`: Compare the labels of source and target alerts. If labels are equal, then the target alert will be inhibited.

Now we need to retstart the alertmanager and prometheus server to apply the changes.

Date of notes: 02/07/2024