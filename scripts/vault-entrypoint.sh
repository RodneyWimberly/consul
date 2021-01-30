#!/bin/sh

# Make our stuff available
source "${CORE_SCRIPT_DIR}"/common-functions.sh
add_path "${CORE_SCRIPT_DIR}"
set +e
# Update existing packages
#su -c "apk update"

# Add required packages
#apk add --no-cache gettext
# curl jq

# Get Docker/Node/Hosting information from the Docker API for use in configuration
hosting_details
export VAULT_ADDR="http://${ETH0_IP}:8200"
export VAULT_API_ADDR="http://${ETH0_IP}:8200"
export VAULT_CLUSTER_ADDR="https://${ETH0_IP}:8201"
log "-----------------------------------------------------------"
log "- Vault Details"
log "-----------------------------------------------------------"
log_detail "Vault Address: ${VAULT_ADDR}"
log_detail "Vault API Address: ${VAULT_API_ADDR}"
log_detail "Vault Cluster Address: ${VAULT_CLUSTER_ADDR}"
log ""

log_detail "merging expanded variables with configuration templates and placing in the config folder"
#cat /vault/templates/vault.json | envsubst > /vault/config/vault.json

cat > /vault/config/vault.json <<EOL
{
  "ui": true,
  "backend": {
    "consul": {
      "address": "consul.service.consul:8500",
      "path": "vault/",
      "scheme": "http"
    }
  },
  "default_lease_ttl": "168h",
  "listener": {
    "tcp": {
      "address": "${ETHO_IP}:8200",
      "tls_disable": "1"
    }
  },
  "max_lease_ttl": "720h"
}
EOL

docker-entrypoint.sh "$@"
