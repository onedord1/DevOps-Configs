FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    apache2-utils \
    bash \
    ca-certificates \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Download pre-built cAdvisor binary
RUN wget https://github.com/google/cadvisor/releases/download/v0.53.0/cadvisor-v0.53.0-linux-amd64 -O /usr/local/bin/cadvisor && \
    chmod +x /usr/local/bin/cadvisor

# Add nginx config and auth
COPY nginx.conf /etc/nginx/conf.d/default.conf
RUN htpasswd -bc /etc/nginx/.htpasswd aesmonitor UdnBf00R@z06

# SSL cert and key
RUN mkdir -p /etc/nginx/ssl
COPY nginx.crt /etc/nginx/ssl/nginx.crt
COPY nginx.key /etc/nginx/ssl/nginx.key

# Add start script
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 443
CMD ["/start.sh"]
