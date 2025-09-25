FROM registry.cloudaes.com/base-images/node:20-alpine AS builder
WORKDIR /app
ARG NEXUS_AUTH_TOKEN \
    VITE_SALES_API_URL \
    VITE_OTEL_EXPORTER_OTLP_ENDPOINT \
    VITE_OTEL_SERVICE_NAME \
    SIGNOZ_USERNAME \
    SIGNOZ_PASSWORD
ENV VITE_SALES_API_URL=${VITE_SALES_API_URL} \
    VITE_OTEL_EXPORTER_OTLP_ENDPOINT=${VITE_OTEL_EXPORTER_OTLP_ENDPOINT} \
    VITE_OTEL_SERVICE_NAME=${VITE_OTEL_SERVICE_NAME} \
    VITE_SIGNOZ_USERNAME=${SIGNOZ_USERNAME} \
    VITE_SIGNOZ_PASSWORD=${SIGNOZ_PASSWORD}

COPY package* .
RUN npm config set strict-ssl false && \
    npm set registry https://172.17.17.242:7443/repository/npm-public/ && \
    npm config set //172.17.17.242:7443/repository/npm-public/:_auth=${NEXUS_AUTH_TOKEN} && \
    npm install --loglevel info
COPY . .
RUN echo "VITE_SALES_API_URL=${VITE_SALES_API_URL}" > .env && \
    npm run test -- --reporter=verbose --run && \
    npm run build-only -- --logLevel info

FROM registry.cloudaes.com/base-images/nginx:1.29.1-alpine-slim
RUN addgroup -g 1001 appgroup && \
    adduser -u 1001 -G appgroup -h /home/appuser -s /bin/sh -D appuser && \
    mkdir -p /run /var/cache/nginx/client_temp /var/cache/nginx/proxy_temp /var/cache/nginx/fastcgi_temp /var/cache/nginx/uwsgi_temp /var/cache/nginx/scgi_temp && \
    touch /run/nginx.pid && \
    chown -R appuser:appgroup /run/nginx.pid /var/cache/nginx /usr/share/nginx/html /home/appuser && \
    chmod -R 755 /run /var/cache/nginx /usr/share/nginx/html /home/appuser 
COPY --from=builder /app/dist /usr/share/nginx/html
COPY ./nginx.conf /etc/nginx/conf.d/default.conf
USER appuser
ENV HOME=/home/appuser
EXPOSE 8000
CMD ["nginx", "-g", "daemon off;"]



#General Dockerfile

# FROM registry.cloudaes.com/base-images/node:20-alpine AS builder

# ARG BRANCH=''
# ARG NEXUS_AUTH_TOKEN

# WORKDIR /app

# COPY package* .

# RUN npm config set strict-ssl false && \
#     npm set registry https://172.17.17.242:7443/repository/npm-public/ && \
#     npm config set //172.17.17.242:7443/repository/npm-public/:_auth=${NEXUS_AUTH_TOKEN} && \
#     npm install --loglevel info

# COPY . .

# COPY ${BRANCH}.env .env

# RUN npm run build-only

# FROM nginx:1.27.0-alpine-slim

# COPY --from=builder /app/dist /usr/share/nginx/html

# COPY ./nginx.conf /etc/nginx/conf.d/default.conf

# EXPOSE 80

# CMD ["nginx", "-g", "daemon off;"]
