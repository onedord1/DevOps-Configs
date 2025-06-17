## Nextcloud Deployment with Dockercompose

**Prerequisite**
- A server with Docker and Docker Compose installed
- Nginx installed in server/VM

**Steps**

- Make a folder named `nextcloud` inside `/var/www/`
- Create a `docker-compose.yaml & .env` and copy/paste the respective yaml content
- Make sure to adjust the `.env` as your need

Finally, After writing the content save the config and run `docker compose up -d`

To browse the Nextcloud simply goto browser and type the hostIP with 8080 port.

**Docker-Compose configuration**

- Creates two Docker volumes for persistent data storage
- Sets up a MariaDB database container for Nextcloud
- Configures the Nextcloud application container
- Establishes networking between the containers
- Maps port 8080 on your host to port 80 in the Nextcloud container

**Configure with Nginx**

Goto `/etc/site-available` by running

`cd /etc/nginx/sites-available`

Then, make a file with any name preferred 'nextcloud'

Copy/Paste the content from nginx.conf to that file

Finally, softlink the file to `/etc/site-enabled` by running below command

`sudo ln -s /etc/sites-available/nextcloud /etc/site-enabled/`

**Testing and Applying the Nginx Configuration**

```verify
sudo nginx -t
sudo systemctl reload nginx
```

Now, you dont need any port with hostIP. Just browse the hostIP to access the Nextcloud.