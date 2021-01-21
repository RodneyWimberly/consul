#!/bin/sh

source "${CONSUL_SCRIPT_DIR}"/common_functions.sh
cmdname=$(basename $0)
add_path ${CONSUL_SCRIPT_DIR}

wait_for_bootstrap_completion

log "The cluster has been bootstrapped"
expand_config_file tls.json
expand_config_file common.json
expand_config_file client.json
expand_config_file gossip.json
expand_config_file general_acl_token.json

show_node_details

log "Starting consul client with the following arguments $@"
exec docker-entrypoint.sh "$@"
