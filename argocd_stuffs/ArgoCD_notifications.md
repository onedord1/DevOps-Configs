
# Ultimate ArgoCD Notifications Setup for Teams

This guide explains how to configure ArgoCD notifications to send alerts to Microsoft Teams, Custom Email & Telegram Channel.

# Microsoft Teams


## Step 1: Configure Teams Webhook

1. Open the Microsoft Teams Desktop or Mobile App.
2. Go to **Apps**.
3. Search for **Incoming Webhook** and click on it.
4. Press **Add to a team** → Select your team and channel → Press **Set up a connector**.
5. Enter a name for your webhook and upload an image (if needed), then press **Create**.
6. Copy the generated webhook URL for later use.

## Step 2: Create Required YAML Files

### 1. `argocd-notifications-cm`

- Create a ConfigMap named `argocd-notifications-cm` in the `argocd` namespace.
- Include the webhook channel variable under `recipientUrls`.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
  namespace: argocd
data:
  service.teams: |
    recipientUrls:
      channelName: $channel-teams-url

  template.app-sync-succeeded: |
    teams:
      themeColor: "#000080"
      sections: |
        [{
          "facts": [
            {
              "name": "Sync Status",
              "value": "{{.app.status.sync.status}}"
            },
            {
              "name": "Repository",
              "value": "{{.app.spec.source.repoURL}}"
            }
          ]
        }]
      potentialAction: |-
        [{
          "@type":"OpenUri",
          "name":"Operation Details",
          "targets":[{
            "os":"default",
            "uri":"{{.context.argocdUrl}}/applications/{{.app.metadata.name}}?operation=true"
          }]
        }]
      title: Application {{.app.metadata.name}} has been successfully synced
      text: Application {{.app.metadata.name}} has been successfully synced at {{.app.status.operationState.finishedAt}}.
      summary: "{{.app.metadata.name}} sync succeeded"
```

### 2. `argocd-notifications-secret`

- Create a Secret named `<secret-name>` in the `argocd` namespace.
- Store the Teams webhook URL under `stringData.channel-teams-url`.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: <secret-name>
  namespace: argocd
stringData:
  channel-teams-url: https://example.com
```

Replace `https://example.com` with the actual webhook URL.

## Step 3: Annotate ArgoCD Applications

- Add the following annotations to your ArgoCD Application manifest to subscribe to notifications.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  annotations:
    notifications.argoproj.io/subscribe.on-sync-succeeded.teams: channelName
```

## Notes

- The `channelName` should match the variable defined in the `argocd-notifications-cm` ConfigMap.
- Ensure that the namespace for both the ConfigMap and Secret is `argocd`.

## Conclusion

By completing the steps above, your ArgoCD applications will send notifications to Microsoft Teams when specific events occur.

_____________________________________________________________________________________________________________________




# ArgoCD Notifications Setup for Email (SMTP)

This guide explains how to configure ArgoCD notifications to send email alerts using the SMTP protocol.

## Step 1: Update `argocd-notifications-cm`

### With Authentication (e.g., Gmail)

Modify the `argocd-notifications-cm` ConfigMap to include the email service configuration. Ensure the namespace is set to `argocd`.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
  namespace: argocd
data:
  service.email.gmail: |
    username: $email-username
    password: $email-password
    host: smtp.gmail.com
    port: 465 # $port
    from: $email-username
  template.app-sync-succeeded: |
    email:
      subject: Application {{.app.metadata.name}} has been successfully synced.
    message: |
      {{if eq .serviceType "slack"}}:white_check_mark:{{end}} Application {{.app.metadata.name}} has been successfully synced at {{.app.status.operationState.finishedAt}}.
      Sync operation details are available at: {{.context.argocdUrl}}/applications/{{.app.metadata.name}}?operation=true .
  trigger.on-sync-succeeded: |
    - when: app.status.operationState.phase == "Succeeded"
      send: 
        - app-sync-succeeded
```

Replace `$email-username`, `$email-password`, and `$port` with appropriate values.

### Without Authentication

For SMTP servers that don't require authentication, you can use the following example:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
  namespace: argocd
data:
  service.email.gmail: |
    host: smtp.example.com
    port: 587 # $port
    from: $email-username
```

Replace `smtp.example.com`, `$port`, and `$email-username` with your SMTP server details.

## Step 2: Update `argocd-notifications-secret`

Store the confidential variables such as `$email-username`, `$email-password`, and `$port` in the `argocd-notifications-secret`.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: argocd-notifications-secret
  namespace: argocd
stringData:
  email-username: example@gmail.com
  email-password: your-secure-password
  port: "465"
```

Ensure the namespace matches the ConfigMap (`argocd`).

## Step 3: Configure Application Triggers

Annotate your ArgoCD applications with the required notifications configuration.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  annotations:
    notifications.argoproj.io/subscribe.on-sync-succeeded.gmail: your_gmail
```

- The `gmail` reference corresponds to the `service.email.gmail` configuration in the ConfigMap.

## Conclusion

Following these steps will enable ArgoCD to send email notifications using the SMTP protocol for various application events.



__________________________________________________________________



# ArgoCD Telegram Notifications Setup



This guide explains how to configure Telegram notifications for ArgoCD using a custom Telegram bot.



## Prerequisites



- Access to ArgoCD installed in your Kubernetes cluster.

- Telegram account.



## Steps to Set Up Telegram Notifications



### 1. Create a Custom Bot



1. Open Telegram and start a conversation with [BotFather](https://t.me/Botfather).

2. Type `/start` to see the list of commands.

3. Type `/newbot` to create a new bot.

4. Provide a unique name for your bot. Once created, BotFather will provide a token to access the bot's HTTP API, e.g.:

756116542280:AAFDspCDyhllkrymZXQbMuoU8HJiVACR9-2Y

Always show details



### 2. Test Your Bot



1. Send a message to your bot on Telegram (e.g., "Hello").

2. Open the following URL to confirm your bot is receiving messages:

https://api.telegram.org/bot<BOT_TOKEN>/getUpdates

Always show details

Replace `<BOT_TOKEN>` with the token from BotFather.

3. Copy the `chatId` from the response. This is required later.



### 3. Configure ArgoCD Notifications



#### Create ConfigMap



Create a ConfigMap named `argocd-notifications-cm` in the `argocd` namespace with the following content:



```yaml

apiVersion: v1

kind: ConfigMap

metadata:

name: argocd-notifications-cm

namespace: argocd

data:

service.telegram: |

 token: $telegram.bot-token             # Replace with your bot token

 chatId: $telegram.chat-id              # Replace with your chat ID

trigger.on-sync-succeeded: |

 - when: app.status.sync.status == 'Synced' && app.status.health.status == 'Healthy'

   send:

     - telegram

template.telegram: |

 message: |

   🚀 Application '{{ .app.metadata.name }}' has been successfully synced and is healthy!

 telegram:

   chatId: $telegram.chat-id            # Replace with your chat ID

```


Create a Secret named argocd-notifications-secret in the argocd namespace to store the bot token and chat ID:

```
apiVersion: v1

kind: Secret

metadata:

  name: argocd-notifications-secret

  namespace: argocd

stringData:

  telegram.bot-token: <your-bot-token>     # Replace with your bot token

  telegram.chat-id: <your-chat-id>         # Replace with your chat ID

```

4. Set Up a Telegram Channel

    Create a new Telegram channel.
    Add your bot as an administrator of the channel.

5. Annotate Your Application

    Add the following annotation to your ArgoCD Application YAML file to enable notifications:

```

apiVersion: argoproj.io/v1alpha1

kind: Application

metadata:

  name: webinar-code-to-cloud

  namespace: argocd

  annotations:

    notifications.argoproj.io/subscribe.on-sync-succeeded.telegram: <your_telegram_channel_name>

```

Replace <your_telegram_channel_name> with your Telegram channel name.

6. Demo application yaml 

```

apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: webinar-code-to-cloud
  namespace: argocd
  annotations:
    notifications.argoproj.io/subscribe.on-sync-succeeded.telegram: argocd_deploy_notifications
    notifications.argoproj.io/subscribe.on-sync-succeeded.teams: channelName
    notifications.argoproj.io/subscribe.on-sync-succeeded.gmail: test@gmail.com
spec:
  project: default
  source:
    repoURL: https://github.com/askyourmentors/webinar-code-to-cloud-conf.git
    targetRevision: HEAD
    path: k8s-manifests
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - Validate=false
    - Prune=true
    - SelfHeal=true
```
