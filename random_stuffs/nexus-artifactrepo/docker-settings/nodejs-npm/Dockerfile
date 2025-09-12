FROM registry.cloudaes.com/base-images/node:20-alpine AS builder

ARG VITE_API_BASE_URL
ARG VITE_RECURRING_CALL
ARG NEXUS_AUTH_TOKEN 

ARG VITE_OTEL_EXPORTER_OTLP_ENDPOINT
# ARG VITE_OTEL_SERVICE_NAME

ENV VITE_OTEL_EXPORTER_OTLP_ENDPOINT=${VITE_OTEL_EXPORTER_OTLP_ENDPOINT}
ENV VITE_OTEL_SERVICE_NAME="quickopsfe-app"

WORKDIR /app

COPY package* .

RUN  echo "$NEXUS_USER"

RUN npm config set strict-ssl false && \
    npm config set registry https://172.17.17.242:7443/repository/npm-public/ && \
    npm config set //172.17.17.242:7443/repository/npm-public/:_auth=${NEXUS_AUTH_TOKEN} && \
    npm install --loglevel info

COPY . .


RUN npm run build-only
RUN npm run docs:build

FROM registry.cloudaes.com/base-images/nginx:1.27.0-alpine-slim

COPY --from=builder /app/dist /usr/share/nginx/html/root
COPY --from=builder /app/docs/.vitepress/dist /usr/share/nginx/html/docs

COPY ./nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
