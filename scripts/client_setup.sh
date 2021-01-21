#!/bin/sh

function setup_config_file() {
  if [ -f "$1"/"$2" ]; then
    echo "Linking $1/$2 to ${CONSUL_CONFIG_DIR}/$2"
    ln -s "$1"/"$2" ${CONSUL_CONFIG_DIR}/"$2"
  else
    echo "$1/$2 was not found, removing ${CONSUL_CONFIG_DIR}/$2"
    rm -f ${CONSUL_CONFIG_DIR}/"$2" > /dev/null
  fi
}

export PATH=${SCRIPT_PATH}:${PATH}
echo "Current Path ${PATH}"
export CONSUL_HTTP=http://${NODE_IP}:8500
export CONSUL_HTTPS=https://${NODE_IP}:8501

if [ ! -f ${CLIENT_BOOTSTRAP_DIR}/.bootstrapped ]; then
  echo "WARNING: The cluster hasn't been bootstrapped"
  echo "All services (Client and Server) are restricted from starup until the bootstrap process has completed"
  until [ -f ${CLIENT_BOOTSTRAP_DIR}/.bootstrapped ]; do sleep 1;echo ' ---- Waiting for consul cluster bootstrapping process to be complete'; done;
fi

echo "The cluster has been bootstrapped"
echo "Linking bootstrap configuration files to the config folder"
setup_config_file ${CLIENT_BOOTSTRAP_DIR} gossip.json
setup_config_file ${CLIENT_BOOTSTRAP_DIR} general_acl_token.json
# Write out configuration that needs environment variables expanded
echo "{\"bind_addr\": \"${NODE_IP}\", \"client_addr\": \"${NODE_IP}\", \"datacenter\": \"${CONSUL_DATACENTER}\", \"data_dir\": \"${CONSUL_DATA_DIR}\", \"node_name\": \"${NODE_NAME}\", \"addresses\": { \"http\": \"${NODE_IP}\" } }" > ${CONSUL_CONFIG_DIR}/client.json

echo ">=>=>=>=>=>  Swarm/Node Details  <=<=<=<=<=<"
echo "Number of Manager Nodes: ${NUM_OF_MGR_NODES}"
echo "Node IP: ${NODE_IP}"
echo "Node ID: ${NODE_ID}"
echo "Node Name: ${NODE_NAME}"
echo "Node Is Manager: ${NODE_IS_MANAGER}"
echo "*******************************************"

echo "Starting consul client with the following arguments $@"
exec docker-entrypoint.sh "$@"
