#!/bin/sh

function link_config_file() {
  if [ -f "${CONSUL_BOOTSTRAP_DIR}/$1" ]; then
    echo "Linking ${CONSUL_BOOTSTRAP_DIR}/$1 to ${CONSUL_CONFIG_DIR}/$1"
    if [ -f "${CONSUL_CONFIG_DIR}/$1" ]; then rm -f "${CONSUL_CONFIG_DIR}/$1"; fi
    ln -s "${CONSUL_BOOTSTRAP_DIR}/$1" "${CONSUL_CONFIG_DIR}/$1"
  else
    echo "${CONSUL_BOOTSTRAP_DIR}/$1 was not found, removing ${CONSUL_CONFIG_DIR}/$1"
    rm -f "${CONSUL_CONFIG_DIR}/$1" > /dev/null
  fi
}

export PATH=${CONSUL_SCRIPT_DIR}:${PATH}

if [ ! -f ${CONSUL_BOOTSTRAP_DIR}/.bootstrapped ]; then
  echo "WARNING: The cluster hasn't been bootstrapped"
  echo "All services (Client and Server) are restricted from starup until the bootstrap process has completed"
  until [ -f ${CONSUL_BOOTSTRAP_DIR}/.bootstrapped ]; do sleep 1;echo ' ---- Waiting for consul cluster bootstrapping process to be complete'; done;
fi

echo "The cluster has been bootstrapped"
echo "Linking bootstrap configuration files to the config folder"
link_config_file gossip.json
link_config_file general_acl_token.json
echo "Generating configuration that needs environment variables expanded into ${CONSUL_CONFIG_DIR}/client.json"
#echo "{\"datacenter\": \"${CONSUL_DATACENTER}\", \"data_dir\": \"${CONSUL_DATA_DIR}\", \"node_name\": \"${NODE_NAME}\", \"addresses\": { \"http\": \"${NODE_IP}\" } }" > ${CONSUL_CONFIG_DIR}/client.json
cat "${CONSUL_BOOTSTRAP_DIR}"/client.json | envsubst > "${CONSUL_CONFIG_DIR}"/client.json

echo ">=>=>=>=>=>  Swarm/Node Details  <=<=<=<=<=<"
echo "Number of Manager Nodes: ${NUM_OF_MGR_NODES}"
echo "Node IP: ${NODE_IP}"
echo "Node ID: ${NODE_ID}"
echo "Node Name: ${NODE_NAME}"
echo "Node Is Manager: ${NODE_IS_MANAGER}"
echo "*******************************************"

echo "Starting consul client with the following arguments $@"
exec docker-entrypoint.sh "$@"
