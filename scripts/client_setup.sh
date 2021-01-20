#!/bin/sh

function setup_config_file() {
  if [ -f "$1"/"$2" ]; then
    ln -s "$1"/"$2" ${CONSUL_CONFIG_DIR}/"$2"
  else
    rm -f ${CONSUL_CONFIG_DIR}/"$2" > /dev/null
  fi
}

export PATH=${SCRIPT_PATH}:${PATH}
echo "Current Path ${PATH}"
export CONSUL_HTTP=http://${NODE_IP}:8500
export CONSUL_HTTPS=https://${NODE_IP}:8501

until [ -f ${CLIENT_BOOTSTRAP_DIR}/.bootstrapped ]; do sleep 1;echo 'waiting for consul configuration for agent clients to be generated'; done;

setup_config_file ${CLIENT_BOOTSTRAP_DIR} gossip.json
setup_config_file ${CLIENT_BOOTSTRAP_DIR} general_acl_token.json
# Write out configuration that needs environment variables expanded
echo "{\"datacenter\": \"${CONSUL_DATACENTER}\", \"data_dir\": \"${CONSUL_DATA_DIR}\", \"node_name\": \"${NODE_NAME}\", \"addresses\": { \"http\": \"${NODE_IP}\" } }" > ${CONSUL_CONFIG_DIR}/client.json

echo "**** >=>=>=>  Swarm Details  <=<=<=< ****"
echo "Number of Manager Nodes: ${NUM_OF_MGR_NODES}"
echo "Node IP: ${NODE_IP}"
echo "Node ID: ${NODE_ID}"
echo "Node Name: ${NODE_NAME}"
echo "Node Is Manager: ${NODE_IS_MANAGER}"
echo "*******************************************"

echo "Starting consul client with the following arguments $@"
exec docker-entrypoint.sh "$@"
