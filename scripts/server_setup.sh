#!/bin/sh

source "${CONSUL_SCRIPT_DIR}"/common_functions.sh
log "Checking current configuration to ensure the cluster is bootstrapped"

set -e

# Set owernership and permission of scripts
chown consul:consul ${CONSUL_SCRIPT_DIR}
chmod u+x ${CONSUL_SCRIPT_DIR}/*.sh

expand_config_file_from common.json
expand_config_file_from server.json

#'{{ GetInterfaceIP \"eth0\" }}'
#'{{ GetAllInterfaces | include "network" "192.168.0.0/16" }}'

show_node_details

log "Starting consul server with the following arguments $@"
exec docker-entrypoint.sh "$@"
