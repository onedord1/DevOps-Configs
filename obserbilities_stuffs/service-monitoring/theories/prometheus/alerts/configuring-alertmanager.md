## Configuring Alertmanager

### Old Versions

In Older Versions of Alertmanager, we have a option called `Matchers` to match the alerts. We can use some type of conditions to match the alerts and send the notifications t particular channels. At that time we had two options like `matcher` and `match_re`. `matcher` is used to match the alerts based on the equality of the labels. `match_re` is used to match the alerts based on the regular expressions.<br>


But in the latest versions of Alertmanager, we don't have this option. We can use `route` to route the alerts to particular channels. Under the `route` section we can define `routes` and under the `routes` we can define `matchers` and `receiver`. `matcher` is used to match the alerts based on labels. `receiver` is used to send notifications to particular channels.

### Configuring Alertmanager

```yaml
global:
  
  smtp_smarthost: 'smtp.gmail.com:587' # SMTP Server
  smtp_from: '' # From Email Address
  smtp_auth_username: '' # SMTP Username
  smtp_auth_password: '' # SMTP Password

route:
  receiver: 'email_receiver_default' # Default Receiver

  routes:
  - receiver: 'email_receiver_1' 
    matchers:
    - severity: page

receivers:
- name: 'email_receiver_1'
  email_configs:
  - to: 'sample@gmail.com'

- name: 'email_receiver_2'
  email_configs:
  - to: 'sample2@gmail.com'
```

In the `alertmanager.yml` file, we define if the alert having the label `severity` with the value `page` then the alert will be sent to the `email_receiver_1`. It will also send the alert to the `email_receiver_default` by default.

**Note:** Once we update the `alertmanager.yml` file, we have to restart the Alertmanager to reflect the changes.

### Configuring Alertmanager to send alerts to Slack

- For sending alerts to Slack, We need to install `Incoming Webhooks` in our Slack channel. We have to be the admin of the Channel where we are going to send alerts. Once installed, we will get the `Webhook URL`. We have to use this URL in the `alertmanager.yml` file.

```yaml
# Under the `receivers` section

- name: 'slack_receiver'
  slack_configs:
  - channel: '#alerts' # We can change our stack Channel name here
    api_url: 'https://hooks.slack.com/services/XXXXXXXXX/XXXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXXX'
```

### Configuring Alertmanager to send alerts to PagerDuty

- For sending alerts to PagerDuty, We need to create a `Service` in the PagerDuty. Once created, we need to add `Prometheus` as the integration. We will get the `Integration Key`. We have to use this key in the `alertmanager.yml` file.

```yaml

# Under the `receivers` section

- name: 'pagerduty_receiver'
  pagerduty_configs:
  - service_key: 'XXXXXXXX'
```

Date of notes: 02/07/2024