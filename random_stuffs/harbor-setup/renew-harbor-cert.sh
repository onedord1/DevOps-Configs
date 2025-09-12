#!/bin/bash

# Exit if any command fails or any variable is unset
set -euo pipefail

# === Configuration ===
DOMAIN="registry.cloudaes.com"
ACME_SH="/root/.acme.sh/acme.sh"
ACME_DIR="/root/.acme.sh/${DOMAIN}_ecc"
HARBOR_SSL_DIR="/etc/harbor/ssl"
HARBOR_DIR="/opt/harbor"
EMAIL="jasim.alam@anwargroup.com"
export DO_API_KEY="dop"

echo "[INFO] Attempting to renew certificate for $DOMAIN..."

# Run acme.sh renewal and capture output
RENEW_OUTPUT=$($ACME_SH --renew -d "$DOMAIN" --ecc --dns dns_dgon 2>&1)

# Check if cert was renewed
if echo "$RENEW_OUTPUT" | grep -q "Skipping"; then
    echo "[INFO] No renewal needed. Skipping cert update and Harbor restart."
    exit 0
elif echo "$RENEW_OUTPUT" | grep -q "Cert success"; then
    echo "[INFO] Certificate was renewed. Proceeding to update Harbor."
else
    echo "[ERROR] Unexpected renewal status. Output:"
    echo "$RENEW_OUTPUT"
    exit 1
fi

# Replace cert and key with the renewed versions
echo "[INFO] Replacing certificate and key..."
cp -f "${ACME_DIR}/fullchain.cer" "${HARBOR_SSL_DIR}/${DOMAIN}.crt"
cp -f "${ACME_DIR}/${DOMAIN}.key" "${HARBOR_SSL_DIR}/${DOMAIN}.key"

# Restart Harbor to apply new certificates
echo "[INFO] Restarting Harbor with updated certificate..."
cd "$HARBOR_DIR"
./prepare
docker compose down
docker compose up -d

echo "[INFO] Harbor successfully restarted with new TLS certificate."
