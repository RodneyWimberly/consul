#!/bin/sh

# Make our stuff available
source "${CORE_SCRIPT_DIR}"/common-functions.sh
add_path "${CORE_SCRIPT_DIR}"
set +e
# Update existing packages
apk update

# Add required packages
apk add --no-cache gettext
#   curl \
#   jq \
#   iputils \
#   iproute2 \
#   bind-tools \
#   gettext \
#   openssl \
#   lshw


# Get Docker/Hosting information from the Docker API for use in configuration
# hosting_details
export CONTAINER_NAME=$(hostname)
export CONTAINER_IP=$(ip -o ro get $(ip ro | awk '$1 == "default" { print $3 }') | awk '{print $5}')
export ETHO_IP=$(ip -o -4 addr list eth0 | head -n1 | awk '{print $4}' | cut -d/ -f1)
export ETH1_IP=$(ip -o -4 addr list eth1 | head -n1 | awk '{print $4}' | cut -d/ -f1)
export ETH2_IP=$(ip -o -4 addr list eth2 | head -n1 | awk '{print $4}' | cut -d/ -f1)
export ETH3_IP=$(ip -o -4 addr list eth3 | head -n1 | awk '{print $4}' | cut -d/ -f1)
export ETH4_IP=$(ip -o -4 addr list eth4 | head -n1 | awk '{print $4}' | cut -d/ -f1)
export VAULT_API_ADDR="http://${ETHO_IP}:8200" VAULT_CLUSTER_ADDR="https://${ETHO_IP}:8201"

log "-----------------------------------------------------------"
log "- Container Details"
log "-----------------------------------------------------------"
log_detail "Container Name: ${CONTAINER_NAME}"
log_detail "Container Address: ${CONTAINER_IP}"
log ""
log "-----------------------------------------------------------"
log "- Network Details"
log "-----------------------------------------------------------"
log_detail "eth0 Address: ${ETHO_IP}"
log_detail "eth1 Address: ${ETH1_IP}"
log_detail "eth2 Address: ${ETH2_IP}"
log_detail "eth3 Address: ${ETH3_IP}"
log_detail "eth4 Address: ${ETH4_IP}"
log ""
log "-----------------------------------------------------------"
log "- Vault Details"
log "-----------------------------------------------------------"
log_detail "Vault API URL: ${VAULT_API_ADDR}"
log_detail "Vault Cluster URL: ${VAULT_CLUSTER_ADDR}"
log ""

log_detail "merging expanded variables with configuration templates and placing in the config folder"
cat /vault/templates/vault.json | envsubst > /vault/config/vault.json

docker-entrypoint.sh "$@"
