# MinIO Docker Setup

This guide provides instructions on how to set up MinIO using Docker Compose.

## Prerequisites

- Docker
- Docker Compose

## Configuration

The `docker-compose.yaml` file configures MinIO with the following settings:

Move this `docker-compose.yaml` into /var/www/minio (make this folder if doesn't exists)

Adjust these env according to your needs

- **Image**: `quay.io/minio/minio`
- **Container Name**: `minio`
- **Restart Policy**: `unless-stopped`
- **Ports**:
  - `9000:9000`: MinIO API Port
  - `9001:9001`: MinIO Console Port
- **Environment Variables**:
  - `MINIO_ROOT_USER`: `superAdmin` <your_desired_username>
  - `MINIO_ROOT_PASSWORD`: `poYG&w#Q8Y&A0GW` <your_desired_psas>
  - `MINIO_SERVER_URL`: `https://172.17.19.252` <host_ip>
  - `MINIO_BROWSER_REDIRECT_URL`: `https://172.17.19.252/console`
- **Volumes**:
  - `/var/www/minio/minio_data:/data`: Persistent storage for MinIO data
- **Command**: `server /data --console-address ":9001"`

## Setup Instructions

1. **Create the Docker Compose File**:
   Save the configuration above into a file named `docker-compose.yml`.

2. **Start MinIO**:
   Run the following command to start the MinIO service:
   ```bash
   docker-compose up -d
