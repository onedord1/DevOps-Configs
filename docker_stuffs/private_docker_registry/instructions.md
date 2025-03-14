
# Local Docker Registry Setup Guide

This guide walks you through the process of setting up and securing a local Docker registry.

## Prerequisites

- Ensure you have `sudo` privileges on your system.
- Update your system's package list and upgrade existing packages.

## Step 1: Install Docker and Docker Compose

1. **Update Your System:**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Install Docker:**
   ```bash
   sudo apt install -y docker.io
   sudo systemctl enable --now docker
   ```

3. **Add User to Docker Group:**
   ```bash
   sudo usermod -aG docker $USER
   newgrp docker
   ```

4. **Verify Docker Installation:**
   ```bash
   docker --version
   ```

## Step 2: Run a Local Docker Registry

1. **Run the Registry:**
   ```bash
   docker run -d -p 5000:5000 --name registry --restart always registry:2
   ```

2. **Verify the Registry is Running:**
   ```bash
   curl http://localhost:5000/v2/
   ```

3. **Check Available Registry Images:**
   ```bash
   curl http://localhost:5000/v2/_catalog
   ```

## Step 3: Secure the Registry with Authentication

1. **Create Authentication Credentials:**
   ```bash
   sudo mkdir -p /etc/docker/registry
   sudo chmod 777 /etc/docker/registry
   ```

2. **Install Apache Utilities (htpasswd):**
   ```bash
   sudo apt update
   sudo apt install -y apache2-utils
   ```

3. **Generate Credentials:**
   ```bash
   htpasswd -Bbn <username> <password> > /etc/docker/registry/htpasswd
   ```

4. **Login to the Private Registry:**
   ```bash
   docker login localhost:5000
   ```

## Step 4: Secure the Registry with SSL/TLS

1. **Install Certbot for SSL Certificates:**
   ```bash
   sudo apt install -y certbot
   ```

2. **Generate an SSL Certificate:**
   ```bash
   sudo certbot certonly --standalone -d-<your_domain_name>
   ```

3. **Run the Registry with SSL & Authentication:**

   At First Stop the running registry 

   ```bash
   docker stop registry && docker rm registry
   ```

   Then run the registry again with 

   ```bash
   docker run -d -p 5000:5000 --name registry --restart always \
   -v /etc/docker/registry:/auth \
   -v /etc/letsencrypt:/certs \
   -e "REGISTRY_AUTH=htpasswd" \
   -e "REGISTRY_AUTH_HTPASSWD_REALM=<your_realm>" \
   -e "REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd" \
   -e "REGISTRY_HTTP_TLS_CERTIFICATE=/certs/live/<domain>/fullchain.pem" \
   -e "REGISTRY_HTTP_TLS_KEY=/certs/live/<domain>/privkey.pem" \
   registry:2
   ```

4. **Test Secure Connection:**
   ```bash
   curl -k -u <user>:'<password>' https://<domain>:5000/v2/
   ```

## Troubleshooting

If you encounter any issues, run the following commands to adjust permissions:

```bash
sudo chmod -R 755 /etc/letsencrypt/
sudo chmod -R 755 /etc/letsencrypt/live/
sudo chmod -R 644 /etc/letsencrypt/live/<domain>/*
sudo chmod -R 644 /etc/letsencrypt/archive/<domain>/*
sudo chmod 640 /etc/docker/registry/htpasswd
sudo chown root:docker /etc/docker/registry/htpasswd
```

---