#!/bin/bash

set -e

source ./scripts/consul.env

echo "*** >=>=>=>  Stack Deployment  <=<=<=< ***"

echo " --> Swarm Details"
export NUM_OF_MGR_NODES=$(docker info --format "{{.Swarm.Managers}}")
echo "Number of Manager Nodes: ${NUM_OF_MGR_NODES}"

export NODE_IP=$(docker info --format "{{.Swarm.NodeAddr}}")
echo "Node IP: ${NODE_IP}"

export NODE_ID=$(docker info --format "{{.Swarm.NodeID}}")
echo "Node ID: ${NODE_ID}"

export NODE_NAME=$(docker info --format "{{.Name}}")
echo "Node Name: ${NODE_NAME}"

export NODE_IS_MANAGER=$(docker info --format "{{.Swarm.ControlAvailable}}")
echo "Node Is Manager: ${NODE_IS_MANAGER}"

echo " --> Validating swarm network infrastructure"
NET_ID=$(docker network ls -f name=admin_network -q)
if [[ -z "$NET_ID" ]]; then
    echo "Creating attachable overlay network 'admin_network'"
    set +e
    docker network create --driver=overlay --attachable --subnet=192.168.1.0/24 admin_network
    set -e
fi

echo " --> Deploying DevOps Stack to Swarm"
docker stack deploy --compose-file=./stacks/devops-stack.yml devops

echo " --> Deploying Logging Stack to Swarm"
docker stack deploy --compose-file=./stacks/logging-stack.yml logging

echo " --> Deploying Consul Stack to Swarm"
docker stack deploy --compose-file=./stacks/consul-stack.yml "${CONSUL_STACK_PROJECT_NAME}"

echo " --> Deploying Diagnostics Stack to Swarm"
docker stack deploy --compose-file=./stacks/diagnostics-stack.yml diagnostics
