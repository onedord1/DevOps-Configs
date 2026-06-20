Kibana base path docs:
1. add required values in kibana CR

```yaml
apiVersion: kibana.k8s.elastic.co/v1
kind: Kibana
metadata:
  name: efk-kibana
  namespace: core-ns
spec:
  version: 8.14.1
  http:
    tls:
      selfSignedCertificate:
        disabled: true
  count: 1
  elasticsearchRef:
    name: efk-elasticsearch
  config:
    server.basePath: "/kibana" # this is base path
    server.rewriteBasePath: true
  podTemplate:
    spec:
      containers:
      - name: kibana
        readinessProbe:
          httpGet:
            path: /kibana # after adding base path we have to modify the readiness prob base path
            port: 5601
            scheme: HTTP
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
          successThreshold: 1
```

2. Now create Ingress resource with path type "Prefix" 

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: kibana-ingress
  namespace: core-ns
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
    - host: kibana.example.com
      http:
        paths:
          - path: /your-base-path
            pathType: Prefix
            backend:
              service:
                name: kibana
                port:
                  number: 5601

```
