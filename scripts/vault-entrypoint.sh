#!/bin/sh

# Make our stuff available
source "${CORE_SCRIPT_DIR}"/common_functions.sh
add_path "${CORE_SCRIPT_DIR}"
set +e
# Update existing packages
apk update

# Add required packages
apk add --no-cache \
  curl \
  jq \
  iputils \
  iproute2 \
  bind-tools \
  gettext \
  openssl \
  lshw


# Get Docker/Node/Hosting information from the Docker API for use in configuration
hosting_details
export VAULT_IP=$(ip -o -4 addr list eth0 | head -n1 | awk '{print $4}' | cut -d/ -f1)
export VAULT_API_ADDR="http://${VAULT_IP}:8200" VAULT_CLUSTER_ADDR="https://${VAULT_IP}:8201"
log_detail "Vault IP: ${VAULT_IP}"
log_detail "Vault API URL: ${VAULT_API_ADDR}"
log_detail "Vault Cluster URL: ${VAULT_CLUSTER_ADDR}"

log_detail "merging expanded variables with configuration templates and placing in the config folder"
cat /vault/templates/vault.json | envsubst > /vault/config/vault.json

docker-entrypoint.sh "$@"
