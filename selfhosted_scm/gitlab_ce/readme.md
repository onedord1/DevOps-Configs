```markdown
# GitLab with Traefik Reverse Proxy Setup Template

This repository provides a template to set up **GitLab CE** behind a **Traefik reverse proxy** using **Docker**. The setup includes **Cloudflare DNS** for SSL certificate management using **Let's Encrypt** and **DNS challenge**.

## Prerequisites

Before setting up, ensure the following:

- A **Cloudflare account** with access to your DNS settings.
- The **gitlab.<your-domain>.com** domain should be added to Cloudflare and point to the server’s public IP.
- Docker and Docker Compose are installed on your server.

### Cloudflare API Credentials

- Create a [Cloudflare API Token](https://developers.cloudflare.com/fundamentals/api/) with permissions to manage DNS records.
- You will need your **Cloudflare API Email** and **API Key** for the Traefik configuration.

---

## File Structure

```plaintext
.
├── config/
│   └── gitlab.rb
├── data/
├── letsencrypt/
│   └── acme.json
├── logs/
└── traefik/
    └── traefik.yaml
```

- `config/gitlab.rb`: GitLab configuration file.
- `data/`: GitLab data storage.
- `letsencrypt/`: Directory to store ACME certificates.
- `logs/`: GitLab logs.
- `traefik/traefik.yaml`: Traefik configuration file.

---

## Setup Instructions

### 1. Clone or Download the Repository

Ensure you have the necessary file structure:

```bash
git clone <repository-url>
cd <repository-directory>
```

### 2. Configure Cloudflare API Credentials

In the `docker-compose.yml` file, replace the `CF_API_EMAIL` and `CF_API_KEY` with your Cloudflare API credentials:

```yaml
environment:
  - CF_API_EMAIL=your-cloudflare-email@example.com
  - CF_API_KEY=your-cloudflare-api-key
```

### 3. Configure Your Domain in Cloudflare

Ensure your domain (e.g., `gitlab.<your-domain>.com`) is added in your Cloudflare dashboard. Then, create an **A record**:

- **Type**: A
- **Name**: `gitlab` (or your subdomain of choice)
- **Content**: `<your-server-public-ip>`
- **Proxy status**: DNS only (gray cloud)

### 4. Update GitLab Configuration

In the `config/gitlab.rb` file, update the following:

```ruby
# SSH Port
gitlab_rails['gitlab_shell_ssh_port'] = 7474  # You can change this port

# External URL
external_url 'http://gitlab.<your-domain>.com'  # Replace with your domain

# Disable Let's Encrypt since Traefik handles it
letsencrypt['enable'] = false

# GitLab Nginx settings
nginx['listen_port'] = 80
nginx['listen_https'] = false
nginx['redirect_http_to_https'] = false
```

### 5. Traefik Configuration

In the `traefik/traefik.yaml` file, replace the email with your own for certificate management:

```yaml
certificatesResolvers:
  cloudflare:
    acme:
      email: your-email@example.com  # Replace with your email
      storage: /letsencrypt/acme.json
      dnsChallenge:
        provider: cloudflare
        resolvers:
          - "1.1.1.1:53"
          - "8.8.8.8:53"
```

### 6. Set Permissions for `acme.json`

The `acme.json` file is where Traefik stores SSL certificates. You need to ensure it has the correct permissions to allow Traefik to write to it:

```bash
chmod 600 ./letsencrypt/acme.json
```

### 7. Running the Docker Containers

Once everything is configured, run the following command to start GitLab and Traefik containers:

```bash
docker-compose up -d
```

This will start the containers in the background.

### 8. Access GitLab

After the containers are up and running, you can access GitLab at:

```plaintext
https://gitlab.<your-domain>.com
```

Traefik will automatically handle SSL certificate creation through Cloudflare and Let's Encrypt.

---

## Notes

- **Cloudflare DNS**: Ensure that your DNS settings in Cloudflare are correctly configured to point to your server's public IP.
- **GitLab External URL**: Ensure `gitlab.<your-domain>.com` is resolvable externally and correctly points to your server.
- **SSL Certificates**: Traefik will handle SSL certificate management for your domain. It will use the **DNS challenge** with Cloudflare to obtain the certificates.

---

## Troubleshooting

- **Issue with SSL certificates**: Ensure the domain's DNS is pointing to the server's public IP, and your Cloudflare API credentials are correct.
- **GitLab login issues**: Check the `logs/` directory for any GitLab-specific errors.
- **Traefik routing issues**: Check the Traefik logs for errors related to routing or certificate generation.

---

### Key Points to Update:

1. **Cloudflare API Credentials**: Replace the placeholder values in the `docker-compose.yml` and `traefik/traefik.yaml` with your actual Cloudflare credentials.
2. **Domain Setup**: Replace `gitlab.<your-domain>.com` with your own domain or subdomain.
3. **Permissions**: Ensure the `chmod 600 ./letsencrypt/acme.json` command is executed for proper file permissions.
4. **GitLab Configuration**: Update the `config/gitlab.rb` file with your desired settings.
5. **Traefik Configuration**: Update the `traefik/traefik.yaml` file with your own email for certificate management.