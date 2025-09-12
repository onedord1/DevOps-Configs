- to enable access logs in traefik, we need to apply this values file where we must need,
```
logs:
  access:
    enabled: true
    format: json
```

- full file content

```
deployment:
  podAnnotations:
    prometheus.io/port: "8082"
    prometheus.io/scrape: "true"
global:
  systemDefaultRegistry: ""
image:
  repository: rancher/mirrored-library-traefik
  tag: 3.3.6
priorityClassName: system-cluster-critical
providers:
  kubernetesIngress:
    publishedService:
      enabled: true
service:
  ipFamilyPolicy: PreferDualStack

tolerations:
- key: CriticalAddonsOnly
  operator: Exists
- effect: NoSchedule
  key: node-role.kubernetes.io/control-plane
  operator: Exists
- effect: NoSchedule
  key: node-role.kubernetes.io/master
  operator: Exists
## add for access logs
logs:
  access:
    enabled: true
    format: json

```
- apply
`helm upgrade traefik traefik/traefik -n kube-system -f traefik-values.yaml`