#!/bin/sh

echo "**** >=>=>=>  Swarm Details  <=<=<=< ****"
echo "Number of Manager Nodes: ${NUM_OF_MGR_NODES}"
echo "Node IP: ${NODE_IP}"
echo "Node ID: ${NODE_ID}"
echo "Node Name: ${NODE_NAME}"
echo "Node Is Manager: ${NODE_IS_MANAGER}"
echo "*******************************************"

export PATH=/usr/local/bin:${PATH}
export CONSUL_HTTP=http://${NODE_IP}:8500
export CONSUL_HTTPS=https://${NODE_IP}:8501

until [ -f ${CLIENTS_BOOTSTRAP_CONFIG}/.bootstrapped ]; do sleep 1;echo 'waiting for consul configuration for agent clients to be generated'; done;

if [ -f ${CLIENTS_BOOTSTRAP_CONFIG}/general_acl_token.json ]; then
    ln -s ${CLIENTS_BOOTSTRAP_CONFIG}/general_acl_token.json ${CONSUL_CONFIG}/general_acl_token.json
else
    rm -f ${CONSUL_CONFIG}/general_acl_token.json > /dev/null
fi

if [ -f ${CLIENTS_BOOTSTRAP_CONFIG}/gossip.json ]; then
    ln -s ${CLIENTS_BOOTSTRAP_CONFIG}/gossip.json ${CONSUL_CONFIG}/gossip.json
else
    rm -f ${CONSUL_CONFIG}/gossip.jsonn > /dev/null
fi
exec ${SCRIPT_PATH}/docker-entrypoint.sh "$@"
