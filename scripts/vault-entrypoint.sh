#!/bin/sh

# Make our stuff available
source "${CORE_SCRIPT_DIR}"/common_functions.sh
add_path "${CORE_SCRIPT_DIR}"

# Update existing packages
apk update

# Add required packages
apk add \
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

set -ex
export VAULT_API_ADDR="http://${DEFAULT_ROUTE_IP}:8200" VAULT_CLUSTER_ADDR="https://${DEFAULT_ROUTE_IP}:8201"
log "Vault API URL: ${VAULT_API_ADDR}"
log "Vault Cluster URL: ${VAULT_CLUSTER_ADDR}"

docker-entrypoint.sh server -config=/vault/config
