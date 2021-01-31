#!/bin/sh

# Make our stuff available
source "${CORE_SCRIPT_DIR}"/common-functions.sh
add_path "${CORE_SCRIPT_DIR}"
set +e

# Get Docker/Node/Hosting information from the Docker API for use in configuration
hosting_details
export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_API_ADDR="http://127.0.0.1:8200"
export VAULT_CLUSTER_ADDR="https://127.0.0.1:8201"
log "-----------------------------------------------------------"
log "- Vault Details"
log "-----------------------------------------------------------"
log_detail "Vault Address: ${VAULT_ADDR}"
log_detail "Vault API Address: ${VAULT_API_ADDR}"
log_detail "Vault Cluster Address: ${VAULT_CLUSTER_ADDR}"
log ""

log_detail "merging expanded variables with configuration templates and placing in the config folder"
cat /vault/templates/vault.json | envsubst > /vault/config/vault.json

docker-entrypoint.sh "$@"
