# collect-ship kubernetes pod logs
- these pods are external from elasticsearch kubernetes clusters
- make sure elasticsearch is exposed in loadbalancer

![enter image description here](./assets/arch-4.png)

## 1. install
```
helm repo add fluent https://fluent.github.io/helm-charts
helm upgrade --install fluent-bit fluent/fluent-bit --values fluentbit/values.yaml
```
