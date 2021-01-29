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

# Add optional packages
apk add \
  bash \
  sudo \
  git \
  screen

# Get Docker/Node/Hosting information from the Docker API for use in configuration
NODE_INFO=$(docker_api "info")
export NUM_OF_MGR_NODES=$(echo ${NODE_INFO} | jq -r -M '.Swarm.Managers')
export NODE_IP=$(echo ${NODE_INFO} | jq -r -M '.Swarm.NodeAddr')
export NODE_ID=$(echo ${NODE_INFO} | jq -r -M '.Swarm.NodeID')
export NODE_NAME=$(echo ${NODE_INFO} | jq -r -M '.Name')
export NODE_IS_MANAGER=$(echo ${NODE_INFO} | jq -r -M '.Swarm.ControlAvailable')
show_docker_details

log "Looking up the IP address for Consul to set as Consul domain owner"
CONSUL_IP=
while [ -z "${CONSUL_IP}" ]; do
  log_detail "waiting 10 seconds for Consul to come up and respond on the IP layer"
  sleep 10

  log_detail "querying for service tasks:core_consul"
  set +e
  CONSUL_IP="`dig +short tasks:core_consul | tail -n1`"
  set -e

  echo "Consul IP: ${CONSUL_IP}"
done
log_detail "merging expanded variables with configuration templates and placing in the config folder"
cat /etc/dnsmasq.template | envsubst > /etc/dnsmasq/dnsmasq.conf

log_detail "Starting DnsMasq"
dnsmasq --no-daemon --log-queries --server=/consul/"$${CONSUL_IP}"#8600
