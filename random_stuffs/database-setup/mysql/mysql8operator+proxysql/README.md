# MySQL (8.0.35) Statefulset With Master/Slave Architecture Using Bitnami MySQL Operator 
## Metadata
 - [ ]  MySQL Version = 8.0.35
 - [ ]  APPLICATION VERSION = 8.0.35
 - [ ]   Operator Version = 9.14.1
 - [ ] Helm/Operator  [Website](https://artifacthub.io/packages/helm/bitnami/mysql)
 - [ ] GitHub Repository [Link](https://github.com/bitnami/charts/tree/main/bitnami/mysql)

## prerequisite:

- [ ]  Kubernetes 1.23+
- [ ] Helm 3.8.0+
- [ ] storageclass support in the underlying infrastructure
- [ ] Get the namespace ready **(created)** referred in the  **values.yaml** file in the `namespaceOverride` block.

## Deploying The HELM Chart
**Remember**
 1. Whenever there is a ORGPOD created, it creates a new namespace. Thus, If required we can deploy a mysql database in the namespace
 2. Helm chart can not be deployed  more than once in each namespace. Else it will yield error.
 3. Helm chart can be deployed in different namespaces in the same cluster.

**How to deploy 1 single CHART**

 1. There is a values.yaml file referring all the configuration of the architecture/operator
 2. apply the file  `helm install unique_name bitnami/mysql --version 9.14.1 --values values.yaml`
 3. Change the storageclass name according to the need
``global.storageClass: "nfs-client"``
4. use the initdbScripts to create predefind user,db,tables

	    initdbScripts:
    	  my_init_script.sql: |
    	    CREATE USER monitor@'%' IDENTIFIED BY 'monitor';
		    FLUSH PRIVILEGES;

**imp:** Create monitor user with monitor password for the proxysql

**How to deploy unique CHART for different ORGPOD in the cluster**
1. Change the name as per the orgpod name `nameOverride: orgpodname`
2. Change the namespace name as per the orgpod name `namespaceOverride: orgpodname`
3. while applying, give the helm a unique name`helm install unique_name bitnami/mysql --version 9.14.1 --values cred.yaml`

# Next Step: ProxySQL
1. Need to add the service name of the master and slave to the proxysql.
convention is **{helm_chart_name}**-**{nameOverride}**-**{master/ slave}**

	    mysql_servers =
	    (
	    { address="my-samplename-slave.default.svc.cluster.local" , port=3306 , hostgroup=10, max_connections=100 }, #hostgrp 10 = slave
	    
	    { address="my-samplename-master.default.svc.cluster.local" , port=3306 , hostgroup=20, max_connections=100 } #hostgrp 20 = master
	    )
2. add application user:

		mysql_users =
		(
		{ username = "akif123", password = "akif123", default_hostgroup = 20, active = 1 }
		)
this one should be refering the user at the value file:

	auth:
	 username: "akif123"
	 password: "akif123"


<hr>

> By Akif