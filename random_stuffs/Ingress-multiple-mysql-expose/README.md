# Multiple mysql instance exposure via ingress
## references
[https://github.com/kubernetes/ingress-nginx/blob/main/docs/user-guide/exposing-tcp-udp-services.md](https://github.com/kubernetes/ingress-nginx/blob/main/docs/user-guide/exposing-tcp-udp-services.md)

 
 [https://stackoverflow.com/questions/57301394/how-to-use-nginx-ingress-tcp-service-on-different-namespace](https://stackoverflow.com/questions/57301394/how-to-use-nginx-ingress-tcp-service-on-different-namespace)
## steps

1. create a namespace
2. create multiple mysql deployment and service in the same namespace
	- mysql-deployment-1
	- mysql-deployment-2	

3. create ingress clusterrole

4. now create config map for mysql service (to be exposed)
```
data:
	unique_ingress_expose_port1: "namespace/service_name_of_mysql_1:port"
	unique_ingress_expose_port2: "namespace/service_name_of_mysql_2:port"
```

**unique_ingress_expose_port =** the port we can use to connect to mysql via ingress endpoint.

    unique_ingress_expose_port1 -> mysql1port-> mysql1instance

    unique_ingress_expose_port2 -> mysql2port-> mysql2instance

5.	add all unique ingress ports to the ingress controller load balancer service,
```
- name: mysql1

  port: 3001

  targetPort: 3001

  protocol: TCP

- name: mysql2

  port: 3002

  targetPort: 3002

  protocol: TCP
```
6. add the config map name to the ingress controller deployment,in the arges section.
```
spec:

# automountServiceAccountToken: true ##only in crd

containers:

- args:

- /nginx-ingress-controller
- -- - - - - - - - - -
- -- - - - - - - - - -
- --tcp-services-configmap=ns/tcp-services
``` 