#!/bin/sh

source "${CONSUL_SCRIPT_DIR}"/consul.env
source "${CONSUL_SCRIPT_DIR}"/common_functions.sh

apk update
apk add \
  bash \
  curl \
  jq \
  openssl \
  gettext \
  iputils \
  nfs-utils \
  bash \
  iproute2 \
  sudo

add_path "${CONSUL_SCRIPT_DIR}"

NODE_INFO=$(docker_api "info")
export NUM_OF_MGR_NODES=$(echo ${NODE_INFO} | jq -r -M '.Swarm.Managers')
export NODE_IP=$(echo ${NODE_INFO} | jq -r -M '.Swarm.NodeAddr')
export NODE_ID=$(echo ${NODE_INFO} | jq -r -M '.Swarm.NodeID')
export NODE_NAME=$(echo ${NODE_INFO} | jq -r -M '.Name')
export NODE_IS_MANAGER=$(echo ${NODE_INFO} | jq -r -M '.Swarm.ControlAvailable')
show_docker_details
if [[ -z "$CONSUL_HTTP_TOKEN" ]] ; then
    if [[ "${NODE_IS_MANAGER}" == "true" ]]; then
      log_detail "The master ACL Token is not present"
      log_detail "Starting the bootstrap process."
      "${CONSUL_SCRIPT_DIR}"/bootstrap_entrypoint.sh
    else
      log_detail "The master ACL Token is not present."
      log_detail "Only servers can bootstrap the cluster."
      log_detail "Exiting, please retry once the cluster is bootstrapped."
    fi
    exit 0
else
    log_detail "The master ACL Token is present"
    log_detail "Skipping the bootstrap process."
fi

expand_config_file_from "common.json"
if [ "${NODE_IS_MANAGER}" == "true" ]; then
  agent_mode="server"
  expand_config_file_from "server.json"
else
  agent_mode="client"
  expand_config_file_from "client.json"
fi

log "Starting Consul in ${agent_mode} mode using the following command: exec docker-entrypoint.sh $@"
exec docker-entrypoint.sh "$@"

log_detail "waiting 1 seconds for server to come up before restoring any snapshots"
sleep 1

if [[ -f "${CONSUL_BOOTSTRAP_DIR}"/bootstrap.snap ]]; then
  log_detail "restoring cluster snapshot '${CONSUL_BOOTSTRAP_DIR}/bootstrap.snap'"
  curl --request PUT --data-binary @"${CONSUL_BOOTSTRAP_DIR}"/bootstrap.snap -sS --header "X-Consul-Token: ${CONSUL_HTTP_TOKEN}" http://127.0.0.1:8500/v1/snapshot
fi
