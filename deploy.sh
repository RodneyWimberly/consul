#!/bin/bash
# DESCRIPTION: Retrieves Node info and populates environment vars for later use,
#   tears down exiting container resources and builds application stacks on bare containers
set -e

source ./scripts/core.env
source ./scripts/common-functions.sh

log "*** >=>=>=>  Stack Deployment  <=<=<=< ***"

export NUM_OF_MGR_NODES=$(docker info --format "{{.Swarm.Managers}}")
export NODE_IP=$(docker info --format "{{.Swarm.NodeAddr}}")
export CONTAINER_ID=$(docker info --format "{{.Swarm.NodeID}}")
export NODE_NAME=$(docker info --format "{{.Name}}")
export NODE_IS_MANAGER=$(docker info --format "{{.Swarm.ControlAvailable}}")
export CONTAINER_IP=$(ip -o ro get $(ip ro | awk '$1 == "default" { print $3 }') | awk '{print $5}')
export ETHO_IP=$(ip -o -4 addr list eth0 | head -n1 | awk '{print $4}' | cut -d/ -f1)
export ETH1_IP=$(ip -o -4 addr list eth1 | head -n1 | awk '{print $4}' | cut -d/ -f1)
export ETH2_IP=$(ip -o -4 addr list eth2 | head -n1 | awk '{print $4}' | cut -d/ -f1)
export ETH3_IP=$(ip -o -4 addr list eth3 | head -n1 | awk '{print $4}' | cut -d/ -f1)
export ETH4_IP=$(ip -o -4 addr list eth4 | head -n1 | awk '{print $4}' | cut -d/ -f1)
show_hosting_details

set +e
log_detail "Removing the following stacks: ${CORE_STACK_NAME}, ${LOGGING_STACK_NAME}, and ${UI_STACK_NAME}"
docker stack rm "${CORE_STACK_NAME}" ${LOGGING_STACK_NAME} ${UI_STACK_NAME}

#log_detail "Removing the following volumes: consul_data_volume"
#docker rm consul_data_volume

#log_detail "Removing network 'admin_network'"
#docker network rm admin_network

log_detail "Waiting 1 seconds for item deletion finalizes"
sleep 1

log_detail "Creating attachable overlay network 'admin_network'"
#docker network create --driver=overlay --attachable --subnet=${CORE_SUBNET} admin_network
docker network create --driver=overlay --attachable admin_network

log_detail "Creating attachable overlay network 'api_network'"
docker network create --driver=overlay --attachable api_network

log_detail "Creating attachable overlay network 'log_network'"
docker network create --driver=overlay --attachable log_network
set -e

#log_detail "Logging into GitHub Registry"
#docker login https://docker.pkg.github.com/ --username=RodneyWimberly --password=b1b203616d5b8f247d0a0749ebc02ecdac81a7d3

# log_detail "Deploying Storage Stack to Swarm"
# docker stack deploy --compose-file=/tmp/consul/storage-stack.yml storage

log_detail "Deploying ${DEVOPS_STACK_NAME} Stack to Swarm"
docker stack deploy --compose-file=./"${DEVOPS_STACK_NAME}"-stack.yml "${DEVOPS_STACK_NAME}"

log_detail "Deploying ${UI_STACK_NAME} Stack to Swarm"
docker stack deploy --compose-file=./"${UI_STACK_NAME}"-stack.yml "${UI_STACK_NAME}"

log_detail "Deploying ${LOGGING_STACK_NAME} Stack to Swarm"
docker stack deploy --compose-file=./"${LOGGING_STACK_NAME}"-stack.yml "${LOGGING_STACK_NAME}"

log_detail "Deploying ${CORE_STACK_NAME} stack to swarm"
docker stack deploy --compose-file=./"${CORE_STACK_NAME}"-stack.yml "${CORE_STACK_NAME}"

# log_detail "Deploying NfsClient Stack to Swarm"
# docker stack deploy --compose-file=/tmp/consul/nfsclient-stack.yml nfsclient

exit
