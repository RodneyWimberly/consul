#!/bin/bash
# DESCRIPTION: Retrieves Node info and populates environment vars for later use,
#   tears down exiting container resources and builds application stacks on bare containers
set -e

source ./scripts/consul.env
source ./scripts/common_functions.sh

log "*** >=>=>=>  Stack Deployment  <=<=<=< ***"

log_detail "Swarm Details"

export NUM_OF_MGR_NODES=$(docker info --format "{{.Swarm.Managers}}")
log "Number of Manager Nodes: ${NUM_OF_MGR_NODES}"

export NODE_IP=$(docker info --format "{{.Swarm.NodeAddr}}")
log "Node IP: ${NODE_IP}"

export NODE_ID=$(docker info --format "{{.Swarm.NodeID}}")
log "Node ID: ${NODE_ID}"

export NODE_NAME=$(docker info --format "{{.Name}}")
log "Node Name: ${NODE_NAME}"

export NODE_IS_MANAGER=$(docker info --format "{{.Swarm.ControlAvailable}}")
log "Node Is Manager: ${NODE_IS_MANAGER}"

log_detail "Removing the following stacks: logging, ${CONSUL_STACK_PROJECT_NAME}"
set +e
docker stack rm "${CONSUL_STACK_PROJECT_NAME}"
#logging

log_detail "Removing the following services: devops_proxy"
#docker service rm devops_proxy
set -e

log_detail "Validating swarm network infrastructure"
NET_ID=$(docker network ls -f name=admin_network -q)

if [[ ! -z "$NET_ID" ]]; then
    log_detail "Removing network 'admin_network'"
    docker network rm admin_network

    log_detail "Waiting 5 seconds for network to be removed"
    sleep 5
fi

log_detail "Creating attachable overlay network 'admin_network'"
set +e
docker network create --driver=overlay --attachable --subnet=${CONSUL_SUBNET} admin_network
set -e

log_detail "Deploying DevOps Stack to Swarm"
docker stack deploy --compose-file=./devops-stack.yml devops

#log_detail "Deploying Logging Stack to Swarm"
#docker stack deploy --compose-file=./logging-stack.yml logging

log_detail "Deploying Consul Stack to Swarm"
docker stack deploy --compose-file=./consul-stack.yml "${CONSUL_STACK_PROJECT_NAME}"

exit
