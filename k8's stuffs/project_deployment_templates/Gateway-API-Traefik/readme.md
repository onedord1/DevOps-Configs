Apply CRD of gateway-api to kubernetes cluster

`kubectl apply -k "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.2.1"`

Then apply the traefik controller

```helm
helm install traefik traefik/traefik \
--version $CHART_VERSION \
--namespace traefik \
--create-namespace \
--set providers.kubernetesGateway.enabled=true \
--set logs.access.enabled=true
```

