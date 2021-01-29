#!/bin/sh

# Make our stuff available
source "${CORE_SCRIPT_DIR}"/common_functions.sh
add_path "${CORE_SCRIPT_DIR}"

# Update existing packages
apk update

# Add required packages
apk add \
  curl \
  jq \
  gettext \
  openssl

# Add optional packages
apk add \
  bash \
  sudo \
  git \
  screen \
  iputils \
  iproute2 \
  nfs-utils

# Get Docker/Node/Hosting information from the Docker API for use in configuration
NODE_INFO=$(docker_api "info")
export NUM_OF_MGR_NODES=$(echo ${NODE_INFO} | jq -r -M '.Swarm.Managers')
export NODE_IP=$(echo ${NODE_INFO} | jq -r -M '.Swarm.NodeAddr')
export NODE_ID=$(echo ${NODE_INFO} | jq -r -M '.Swarm.NodeID')
export NODE_NAME=$(echo ${NODE_INFO} | jq -r -M '.Name')
export NODE_IS_MANAGER=$(echo ${NODE_INFO} | jq -r -M '.Swarm.ControlAvailable')
show_docker_details

# Do we need to create a bootstrap snapshot? A bootstrap snapshot is necessary to configure
# a new cluster. No agents can talk to other agents until the cluster bootstrap has
# been restored. The bootstrap snapshot process does the following tasks:
#   1. Elect a leader
#   2. Setup ACL
#   3. Setup encryption
#   4. Setup TLS
#   5. Certificate creation
#   6. Take a snapshot
if [[ -z "$CONSUL_HTTP_TOKEN" ]] ; then
    if [[ "${NODE_IS_MANAGER}" == "true" ]]; then
      log_detail "The master ACL Token is not present"
      log_detail "Starting the bootstrap process."
      "${CORE_SCRIPT_DIR}"/bootstrap_entrypoint.sh
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

# Do we need to restore a bootstrap snapshot?
# If order to restore a bootstrap snapshot don't forget to do the follow steps
# after the bootstrap creation to ensure the information is provided to all nodes.
# This necessary to bring up a new cluster (Great for dev/test/stage environments)
#   1. Update core.env, server.config, & client.config in the
#      source config folder with ACL token values in bootstrap.json
#   2. Make sure new certs (ca.crt, cert.crt. and tls.key) and
#      bootstrap.snap are in the source backups folder
#   3. If a file named 'bootstrap.restored' exists in the backup
#      or bootstrap folders then delete it.
if [[ -f "${CONSUL_BOOTSTRAP_DIR}"/bootstrap.snap ]] &&
  [[ ! -f "${CONSUL_BOOTSTRAP_DIR}"/bootstrap.restored ]] &&
  [ "${NODE_NAME}" == "manager1" ]; then
  restore_snapshot "${CONSUL_BOOTSTRAP_DIR}"/bootstrap.snap
  touch "${CONSUL_BOOTSTRAP_DIR}"/bootstrap.restored
fi

# Merge expanded variables with configuration templates and place in the config folder
expand_config_file_from "common.json"
if [ "${NODE_IS_MANAGER}" == "true" ]; then
  agent_mode="server"
  expand_config_file_from "server.json"
else
  agent_mode="client"
  expand_config_file_from "client.json"
fi

# Start Consul the same way it would have started if we didn't modify the containers Entry Point
log "Starting Consul in ${agent_mode} mode using the following command: exec docker-entrypoint.sh $@"
docker-entrypoint.sh "$@" -join tasks:"${CORE_STACK_NAME}"_consul
