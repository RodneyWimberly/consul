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
  iputils \
  iproute2 \
  bind-tools \
  gettext \
  openssl

# Get Docker/Node/Hosting information from the Docker API for use in configuration
docker_details

# Merge expanded variables with configuration templates and place in the config folder
expand_config_file_from "common.json"
if [ "${NODE_IS_MANAGER}" == "true" ]; then
  agent_mode="server"
  expand_config_file_from "server.json"
else
  agent_mode="client"
  expand_config_file_from "client.json"
fi

log "Starting Consul in ${agent_mode} mode using the following command: exec docker-entrypoint.sh $@  -join consul.service.consul"
docker-entrypoint.sh "$@" -join consul.service.consul
