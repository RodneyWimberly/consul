#!/bin/sh

# Make our stuff available
source /usr/local/scripts/consul.env
source /usr/local/scripts/common_functions.sh
add_path /usr/local/scripts/

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

set +e
log "Looking up the IP address for Consul to set as Consul domain owner"
while true; do
  log_detail "waiting 10 seconds for Consul to come up and respond on the IP layer"
  sleep 10

  log_detail "querying for service tasks.consul_consul"
  CONSUL_IP="`dig +short tasks.consul_consul | tail -n1`"

  log_detail "merging expanded variables with configuration templates and placeing in the config folder"
  cat /etc/dnsmasq.template | envsubst > /etc/dnsmasq/dnsmasq.conf

  log_detail "Starting DnsMasq"
  dnsmasq --no-daemon --log-queries --server=/consul/"$${CONSUL_IP}"#8600
done
