argocd login argocd-server.argocd.svc.cluster.local:443 --insecure

VJUWqegYXVE

argocd account list
argocd account update-password --account developer


apiVersion: v1
data:
  accounts.developer: login
kind: ConfigMap
metadata:
  labels:
    app.kubernetes.io/name: argocd-cm
    app.kubernetes.io/part-of: argocd
  name: argocd-cm
  namespace: argocd
~                                                


apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-rbac-cm
  namespace: argocd
data:
  policy.default: role:readonly
  policy.csv: |
    p, role:developer, applications, get, *, allow
    p, role:developer, applications, sync, *, allow
    g, developer, role:developer


---
ulpKy0A5AqSpKHDnulpKy0A5AqSpKHDn

apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-rbac-cm
  namespace: argocd
data:
  policy.default: role:readonly
  policy.csv: |
....
....
    #test user er jonno
    p, role:test, logs, get, default/dev-quickops*, allow
    p, role:test, exec, create, default/dev-quickops*, allow
    p, role:test, applications, get, default/dev-quickops*, allow
    p, role:test, applications, sync, default/dev-quickops*, allow
    g, test, role:test
