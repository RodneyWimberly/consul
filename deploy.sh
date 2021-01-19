#!/bin/bash

set -e

source ./scripts/consul.env

echo "*** >=>=>=>  Deployment Details  <=<=<=< ***"
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
echo "********************************************"

echo "************ Configuring Swarm *************"

echo " --> Validating swarm network infrastructure"
NET_ID=$(docker network ls -f name=consul_network -q)
if [[ -z "$NET_ID" ]]; then
    echo " --> Creating attachable overlay network 'consul_network'"
    set +e
    docker network create --driver=overlay --attachable --subnet=192.168.1.0/24 consul_network
    set -e
fi

echo " --> Deploying DevOps Stack to Swarm"
docker stack deploy --compose-file=./devops-stack.yml devops

echo " --> Deploying Consul Stack to Swarm"
docker stack deploy --compose-file=./consul-stack.yml "${CONSUL_STACK_PROJECT_NAME}"
