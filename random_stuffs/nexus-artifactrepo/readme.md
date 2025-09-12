# Nexus Artifact Hub Setup Guide

This guide walks you through installing and configuring Sonatype Nexus Repository Manager using Docker Compose and NGINX as a reverse proxy with SSL encryption.

## Prerequisites

- A Linux server VM with sudo privileges.
- Docker and Docker Compose installed.
- NGINX installed.

## 1. Prepare Nexus Data Directory

1. SSH into your server VM.
2. Create a directory for Nexus:
   ```bash
   sudo mkdir -p /var/www/nexus-repo/nexus-data
   cd /var/www/nexus-repo
   ```
3. Download or create the `docker-compose.yaml` file in this directory. You can use the provided template:
   ```yaml
   version: '3'
   services:
     nexus:
       image: sonatype/nexus3:latest
       container_name: nexus
       ports:
         - '8081:8081'
         - '8443:8443'
       volumes:
         - ./nexus-data:/nexus-data
       restart: unless-stopped
   ```
4. Adjust ownership and permissions of the data folder:
   ```bash
   sudo chown -R 200:200 nexus-data
   sudo chmod -R 750 nexus-data
   ```
5. Start Nexus:
   ```bash
   sudo docker-compose up -d
   ```

## 2. Configure NGINX as a Reverse Proxy

1. Ensure NGINX is installed:
   ```bash
   sudo apt update
   sudo apt install -y nginx
   ```
2. Create directories for SSL certificates:
   ```bash
   sudo mkdir -p /etc/nginx/certs
   ```
3. Generate a self-signed SSL certificate (replace example.com with your domain or server IP):
   ```bash
   sudo openssl req -x509 -nodes -days 365 \
     -newkey rsa:2048 \
     -keyout /etc/nginx/certs/nexus.key \
     -out /etc/nginx/certs/nexus.crt \
     -subj "/C=US/ST=State/L=City/O=Organization/OU=Unit/CN=example.com"
   ```
4. Create an NGINX site configuration file `/etc/nginx/sites-available/nexus` like following content:
   ```nginx
   server {
       listen 80;
       server_name example.com;  # Replace with your domain or IP
       return 301 https://$host$request_uri;
   }

   server {
       listen 7443 ssl;
       server_name example.com;  # Replace with your domain or IP

       ssl_certificate     /etc/nginx/certs/nexus.crt;
       ssl_certificate_key /etc/nginx/certs/nexus.key;
       ssl_protocols       TLSv1.2 TLSv1.3;
       ssl_ciphers         HIGH:!aNULL:!MD5;

       location / {
           proxy_pass         http://127.0.0.1:8081;
           proxy_set_header   Host $host;
           proxy_set_header   X-Real-IP $remote_addr;
           proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header   X-Forwarded-Proto $scheme;
       }
   }
   ```
Reference: [NGINX Configuration](./nginx.conf)

5. Enable the site and reload NGINX:
   ```bash
   sudo ln -s /etc/nginx/sites-available/nexus /etc/nginx/sites-enabled/
   sudo nginx -t && sudo systemctl reload nginx
   ```

## 3. Access Nexus Repository Manager

Open your browser and navigate to:

```
https://<server-ip-or-domain>:7443
```

> Note: If you used a self-signed certificate, your browser will warn about an untrusted certificate. You can safely proceed after accepting the warning.

## 4. Retrieve Initial Admin Password

Run the following command to get the default administrator password:

```bash
sudo docker-compose exec nexus cat /nexus-data/admin.password
```

Use this password to log in for the first time at the Nexus UI. Remember to change it after logging in.

# Troubleshoot

## Overview
This guide provides instructions on how to configure your application to use the Nexus Repository Manager. This involves updating the Dockerfile and ensuring the correct settings are in place.

## Steps to Configure Nexus Repository Manager

### 1. Update the Dockerfile
To use the Nexus Repository Manager, you need to tweak your application's Dockerfile. Below is an example of an updated Dockerfile:

Reference: [Dockerfile](./docker-settings/dockerfile.sample)

### 2. Configure settings.xml
Ensure that your `settings.xml` file is correctly configured to connect with the Nexus Repository. Here is an example of what your `settings.xml` might look like:

## Sample `XML` configuration for Nexus Repository Manager

```xml
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 http://maven.apache.org/xsd/settings-1.0.0.xsd">
  <servers>
    <server>
      <id>nexus</id>
      <username>admin</username>
      <password>Va68!&$4&g67F</password>
    </server>
  </servers>
  <profiles>
    <profile>
      <id>nexus</id>
      <repositories>
        <repository>
          <id>central</id>
          <url>https://<server-ip-or-domain>:7443/repository/maven-public/</url>
          <releases><enabled>true</enabled></releases>
          <snapshots><enabled>true</enabled></snapshots>
        </repository>
      </repositories>
    </profile>
  </profiles>
  <activeProfiles>
    <activeProfile>nexus</activeProfile>
  </activeProfiles>
</settings>
```
Reference : [settings.xml](./docker-settings/settings-docker.xml)

Make sure to replace `https://<server-ip-or-domain>:7443/repository/maven-public/` with your actual Nexus Repository URL.

### 3. Adding Custom Proxy Repository
You can add a custom proxy repository inside the Nexus Repository Manager by following these steps:

1. Log in to the Nexus Repository Manager.
2. Go to **Settings** > **Repository** > **Create Repository**.
3. Fill in the required details and save the repository.

### 4. Building the Docker Image
Once your Dockerfile and `settings.xml` are configured, you can build your Docker image using the following command:

```sh
docker build --build-arg NEXUS_USER="$NEXUS_USER" --build-arg NEXUS_PASS="$NEXUS_PASS" -t "$IMAGE_NAME:$IMAGE_TAG" -f dockerfiles/dockerfile.dev .
```

Make sure that the environment variables `$NEXUS_USER`, `$NEXUS_PASS`, `$IMAGE_NAME`, and `$IMAGE_TAG` are properly set before running this command.

### 5. Proxy read timeout

If you encounter issues with proxy read timeouts, you can adjust the timeout settings in the Docker Compose file. Here is an example of how to modify the `nexus.properties` under `/var/www/nexus-repo/nexus-data/etc/nexus.properties` with values

```bash
jetty.http.idleTimeout=600000
jetty.https.idleTimeout=600000
```
this config will wait the nexus repo to be idle for 600000 milliseconds before closing the connection. You can adjust this value based on your specific requirements.
