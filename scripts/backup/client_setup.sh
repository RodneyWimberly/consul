#!/bin/sh

source "${CONSUL_SCRIPT_DIR}"/bootstrap/common_functions.sh
add_path ${CONSUL_SCRIPT_DIR}bootstrap/

wait_for_bootstrap_completion

log "The cluster has been bootstrapped"
expand_config_file_from tls.json
expand_config_file_from common.json
expand_config_file_from client.json
expand_config_file_from gossip.json
expand_config_file_from general_acl_token.json

show_node_details

log "Starting consul client with the following arguments $@"
exec docker-entrypoint.sh "$@"
