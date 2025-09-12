FROM registry.cloudaes.com/base-images/node:20-alpine AS builder

ARG BRANCH=''
ARG NEXUS_AUTH_TOKEN

WORKDIR /app

COPY package* .

RUN npm config set strict-ssl false && \
    npm set registry https://172.17.17.242:7443/repository/npm-public/ && \
    npm config set //172.17.17.242:7443/repository/npm-public/:_auth=${NEXUS_AUTH_TOKEN} && \
    npm install --loglevel info

COPY . .

COPY ${BRANCH}.env .env

RUN npm run build-only

FROM nginx:1.27.0-alpine-slim

COPY --from=builder /app/dist /usr/share/nginx/html

COPY ./nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
