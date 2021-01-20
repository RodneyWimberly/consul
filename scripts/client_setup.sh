#!/bin/sh

setup-config-file() {
  if [ -f "$1"/"$2" ]; then
    ln -s "$1"/"$2" ${CONSUL_CONFIG_DIR}/"$2"
  else
    rm -f ${CONSUL_CONFIG_DIR}/"$2" > /dev/null
  fi
}

echo "**** >=>=>=>  Swarm Details  <=<=<=< ****"
echo "Number of Manager Nodes: ${NUM_OF_MGR_NODES}"
echo "Node IP: ${NODE_IP}"
echo "Node ID: ${NODE_ID}"
echo "Node Name: ${NODE_NAME}"
echo "Node Is Manager: ${NODE_IS_MANAGER}"
echo "*******************************************"

# Write out configuration that needs environment variables expanded
echo "{\"datacenter\": \"${CONSUL_DATACENTER}\", \"data_dir\": \"${CONSUL_DATA_DIR}\", \"node_name\": \"${NODE_NAME}\", \"server\": ${NODE_IS_MANAGER}, \"addresses\": { \"http\": \"${NODE_IP}\" } }" > ${CONSUL_CONFIG_DIR}/client.json

export PATH=${SCRIPT_PATH}:${PATH}
echo "Current Path ${PATH}"
export CONSUL_HTTP=http://${NODE_IP}:8500
export CONSUL_HTTPS=https://${NODE_IP}:8501

until [ -f ${CLIENT_BOOTSTRAP_DIR}/.bootstrapped ]; do sleep 1;echo 'waiting for consul configuration for agent clients to be generated'; done;

setup-config-file ${CLIENT_BOOTSTRAP_DIR} gossip.json
setup-config-file ${CLIENT_BOOTSTRAP_DIR} general_acl_token.json

exec docker-entrypoint.sh "$@"
