#!/bin/bash
# DESCRIPTION: Retrieves Node info and populates environment vars for later use,
#   tears down exiting container resources and builds application stacks on bare containers
set -e

source /tmp/consul/scripts/consul.env
source /tmp/consul/scripts/common_functions.sh

log "*** >=>=>=>  Stack Deployment  <=<=<=< ***"

export NUM_OF_MGR_NODES=$(docker info --format "{{.Swarm.Managers}}")
export NODE_IP=$(docker info --format "{{.Swarm.NodeAddr}}")
export NODE_ID=$(docker info --format "{{.Swarm.NodeID}}")
export NODE_NAME=$(docker info --format "{{.Name}}")
export NODE_IS_MANAGER=$(docker info --format "{{.Swarm.ControlAvailable}}")
show_node_details

set +e
log_detail "Removing the following stacks: logging, ${CONSUL_STACK_PROJECT_NAME}"
docker stack rm "${CONSUL_STACK_PROJECT_NAME}"

#log_detail "Removing the following volumes: consul_data_volume"
#docker rm consul_data_volume

#log_detail "Removing network 'admin_network'"
#docker network rm admin_network

log_detail "Waiting 10 seconds for item deletion finalizes"
sleep 10

log_detail "Creating attachable overlay network 'admin_network'"
docker network create --driver=overlay --attachable --subnet=${CONSUL_SUBNET} admin_network
set -e

log_detail "Deploying DevOps Stack to Swarm"
docker stack deploy --compose-file=../../devops-stack.yml devops

#log_detail "Deploying Logging Stack to Swarm"
#docker stack deploy --compose-file=./logging-stack.yml logging

log_detail "Deploying Consul Stack to Swarm"
docker stack deploy --compose-file=../../consul-stack.yml "${CONSUL_STACK_PROJECT_NAME}"

exit