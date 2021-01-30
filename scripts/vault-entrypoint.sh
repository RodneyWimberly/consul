#!/bin/sh

# Make our stuff available
source "${CORE_SCRIPT_DIR}"/common_functions.sh
add_path "${CORE_SCRIPT_DIR}"

set -ex
#IP is the IP address of the default networking route
export IP=$(ip -o ro get $(ip ro | awk '$1 == "default" { print $3 }') | awk '{print $5}')
export VAULT_API_ADDR="http://${IP}:8200" VAULT_CLUSTER_ADDR="https://${IP}:8201"
docker-entrypoint.sh server -config=/vault/config
