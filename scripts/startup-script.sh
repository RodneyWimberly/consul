#!/bin/sh
source "${CONSUL_SCRIPT_DIR}"/consul.env

apk update
apk add bash curl jq gettext

export PATH=$1:${PATH}

# Expand Config Files
set +e
rm -f "${CONSUL_CONFIG_DIR}/common.json"
cat "${CONSUL_BOOTSTRAP_DIR}/common.json" | envsubst > "${CONSUL_CONFIG_DIR}/common.json"
echo $(cat "${CONSUL_CONFIG_DIR}/common.json")
if [[ ${NODE_IS_MANAGER} -eq "true" ]]; then
    rm -f "${CONSUL_CONFIG_DIR}/server.json"
    cat "${CONSUL_BOOTSTRAP_DIR}/server.json" | envsubst > "${CONSUL_CONFIG_DIR}/server.json"
    echo $(cat "${CONSUL_CONFIG_DIR}/server.json")
else
    rm -f "${CONSUL_CONFIG_DIR}/client.json"
    cat "${CONSUL_BOOTSTRAP_DIR}/client.json" | envsubst > "${CONSUL_CONFIG_DIR}/client.json"
    echo $(cat "${CONSUL_CONFIG_DIR}/client.json")
fi
set -e

# Make sure we are bootstrapped
if [[ -z ${CONSUL_HTTP_TOKEN} ]]; then
    echo "ERROR: cluster hasn't been bootstrapped"
    echo "ERROR: All services (Client and Server) are restricted from starup until the bootstrap process has completed"
else
    echo ">=>=>=>=>=>  Swarm/Node Details  <=<=<=<=<=<"
    echo "Number of Manager Nodes: ${NUM_OF_MGR_NODES}"
    echo "Node IP: ${NODE_IP}"
    echo "Node ID: ${NODE_ID}"
    echo "Node Name: ${NODE_NAME}"
    echo "Node Is Manager/Server: ${NODE_IS_MANAGER}"

    echo "Starting consul client with the following arguments $@"
    exec docker-entrypoint.sh "$@"
fi