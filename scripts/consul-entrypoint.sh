#!/bin/sh

source "${CONSUL_SCRIPT_DIR}"/consul.env
source "${CONSUL_SCRIPT_DIR}"/common_functions.sh

apk update
apk add bash curl jq gettext

add_path "${CONSUL_SCRIPT_DIR}:${CONSUL_SCRIPT_DIR}/bootstrap"
get_node_details

expand_config_file_from "common.json"
if [ "${NODE_IS_MANAGER}" == "true" ]; then
  expand_config_file_from "server.json"
else
  expand_config_file_from "client.json"
fi

if [[ -z ${CONSUL_HTTP_TOKEN} ]] || [[ ${CONSUL_HTTP_TOKEN} == 0 ]]; then
  log_error "Cluster hasn't been bootstrapped"
  log_error "All services (Client and Server) are restricted from starup until the bootstrap process has completed"
  if [ "${NODE_IS_MANAGER}" == "true" ]; then
    ${CONSUL_SCRIPT_DIR}/bootstrap/server_bootstrap.sh
  fi
fi

show_node_details
echo "Starting consul client with the following arguments $@"
exec docker-entrypoint.sh "$@"
