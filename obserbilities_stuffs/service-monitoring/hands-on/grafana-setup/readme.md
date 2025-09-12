## Setup Grafana with Docker and Nginx for Reverse Proxy

This guide outlines how to set up Grafana using Docker and Nginx as a reverse proxy.

**Prerequisites:**

*   Docker and Docker Compose installed on your server.
*   Nginx installed on your server.

**Steps:**

1.  **Docker Compose Setup:**

    *   Copy the content from `docker-compose.yml` into `/var/www/grafana/docker-compose.yml`.  Create the directory if it doesn't exist: `sudo mkdir -p /var/www/grafana`
    *   Navigate to the directory: `cd /var/www/grafana`
    *   Run `docker compose up -d` to start Grafana and its dependencies.

2.  **Nginx Configuration:**

    *   Copy the content from `nginx.conf` and paste it into `/etc/nginx/sites-available/grafana`. You may need to create this file. Use `sudo` to edit the file.
    *   Create a symbolic link to enable the configuration:

        ```bash
        sudo ln -s /etc/nginx/sites-available/grafana /etc/nginx/sites-enabled
        ```

    *   Verify the Nginx configuration:

        ```bash
        sudo nginx -t
        ```

    *   Restart the Nginx service:

        ```bash
        sudo systemctl restart nginx
        ```

3.  **Access Grafana:**

    *   Browse to the frontend using your server's IP address or domain name, followed by `/grafana`: `<server_ip/grafana>` or `<your_domain/grafana>`.
