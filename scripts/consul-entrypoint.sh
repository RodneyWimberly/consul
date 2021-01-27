#!/bin/sh

source "${CONSUL_SCRIPT_DIR}"/consul.env
source "${CONSUL_SCRIPT_DIR}"/common_functions.sh

apk update
apk add \
  bash \
  curl \
  jq \
  gettext \
  iputils \
  nfs-utils \
  bash \
  iproute2

add_path "${CONSUL_SCRIPT_DIR}"

NODE_INFO=$(docker_api "info")
export NUM_OF_MGR_NODES=$(echo ${NODE_INFO} | jq -r -M '.Swarm.Managers')
export NODE_IP=$(echo ${NODE_INFO} | jq -r -M '.Swarm.NodeAddr')
export NODE_ID=$(echo ${NODE_INFO} | jq -r -M '.Swarm.NodeID')
export NODE_NAME=$(echo ${NODE_INFO} | jq -r -M '.Name')
export NODE_IS_MANAGER=$(echo ${NODE_INFO} | jq -r -M '.Swarm.ControlAvailable')

expand_config_file_from "common.json"
if [ "${NODE_IS_MANAGER}" == "true" ]; then
  agent_mode="server"
  expand_config_file_from "server.json"
else
  agent_mode="client"
  expand_config_file_from "client.json"
fi

if [ -z "$CONSUL_HTTP_TOKEN" ] || [ "$CONSUL_HTTP_TOKEN" -eq "0" ] ; then
    # log 'Waiting before inquiring if the Consul cluster bootstrapping service to be complete'
    # ${CONSUL_SCRIPT_DIR}/wait-for-it.sh --timeout=300 --host=consul-bootstrapper.service.consul --port=80 --strict -- echo "consul-bootstrapper found" || (echo "Failed to locate consul-bootstrapper" && exit 1)

    # sleep 5
    # log_detail "Querying the bootstrap process to see if it has completed."
    # curl http://consul-bootstrapper.service.consul/${agent_mode}.json -o ${CONSUL_CONFIG_DIR}/${agent_mode}.json
    "${CONSUL_SCRIPT_DIR}"/bootstrap_entrypoint.sh

    log_detail "The consul cluster has been successfully bootstrapped."
else
    log_detail "The master ACL Token is present so skipping the bootstrap process."
fi

show_docker_details

log_detail "Starting Consul in ${agent_mode} mode using the following command: exec docker-entrypoint.sh $@"
exec docker-entrypoint.sh "$@"
