## Configuring Grafana

If we need to Configure our Grafana instance, we need to access the `defaults.ini` file. This file will contains the default configuration of our Grafana instance. We can find the `defaults.ini` file in the `conf` directory of the Grafana installation directory for Windows and in the `/etc/grafana` directory for Linux/Docker. The best practice is to create a copy of the `defaults.ini` file and make changes to the copied file. 

### Tips to Configure Grafana:

- If we want to chnage some default configurations like port, data directory, etc. we need to remove `;` from the beginning of the line and make the changes.

- Once we made the changes, we need to restart the Grafana service to apply the changes.
```bash
sudo systemctl restart grafana-server
```

### Databases configuration for Grafana:

- By default, Grafana uses `SQLite` as the default database. If we need to use some external databases, we can use `MySQL` or `PostgreSQL`. For that we need to update the `defaults.ini` file.

**When to use External Database?**

- If we have two or more Grafana instances, We can use some external database like MySQL or PostgreSQL is best. Because, in case if we lose our server or docker container. we can backup the database and restore it on another server or container to import the dashboards and data.

- If we want to have our multiple grafana instances to share the same dashboards and data, we can use the external database as shared storage.

Date of notes: 04/07/2024