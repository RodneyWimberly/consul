#!/bin/sh

# Make our stuff available
source "${CORE_SCRIPT_DIR}"/common-functions.sh
add_path "${CORE_SCRIPT_DIR}"
set +e
# Update existing packages
#su -c "apk update"

# Add required packages
apk add --no-cache gettext
# curl jq

# Get Docker/Node/Hosting information from the Docker API for use in configuration
hosting_details
# log "-----------------------------------------------------------"
# log "- Vault Details"
# log "-----------------------------------------------------------"
# log_detail "Vault API URL: ${VAULT_API_ADDR}"
# log_detail "Vault Cluster URL: ${VAULT_CLUSTER_ADDR}"
# log ""

log_detail "merging expanded variables with configuration templates and placing in the config folder"
cat /vault/templates/vault.json | envsubst > /vault/config/vault.json

docker-entrypoint.sh "$@"
