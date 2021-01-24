#!/bin/sh

source "${CONSUL_SCRIPT_DIR}"/consul.env
source "${CONSUL_SCRIPT_DIR}"/common_functions.sh

apk update
apk add bash curl jq gettext

add_path "${CONSUL_SCRIPT_DIR}"

get_docker_details

expand_config_file_from "common.json"
if [ "${NODE_IS_MANAGER}" == "true" ]; then
  agent_mode="server"
  expand_config_file_from "server.json"
else
  agent_mode="client"
  expand_config_file_from "client.json"
fi

wait_for_bootstrap_process

show_docker_details

log_detail "Starting Consul in ${agent_mode} mode using the following command: exec docker-entrypoint.sh $@"
exec docker-entrypoint.sh "$@"
