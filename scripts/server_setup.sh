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

echo "Checking current configuration to ensure the cluster is bootstrapped"

## ensure consul is yet not running - important due to supervisor restart
pkill consul

set -e

mkdir -p ${CONSUL_BOOTSTRAP_DIR}
mkdir -p ${CONSUL_BOOTSTRAP_DIR}

# Make sure consul user has access to our new folders
chown consul:consul ${CONSUL_BOOTSTRAP_DIR}
chown consul:consul ${CONSUL_BOOTSTRAP_DIR}
chown consul:consul ${CONSUL_SCRIPT_DIR}

# Make sure our all our scripts are marked executable
chmod u+x ${CONSUL_SCRIPT_DIR}/*.sh

if [ -z "${CONSUL_ENABLE_APK}" ]; then
	echo "The enable APK flag is disabled, please ensure these dependencies are installed: bash curl jq openssl"
else
	apk update
	apk add bash curl jq openssl
fi

export PATH=${CONSUL_SCRIPT_DIR}:${PATH}
echo "Current Path ${PATH}"
export CONSUL_HTTP=http://${NODE_IP}:8500
export CONSUL_HTTPS=https://${NODE_IP}:8501

# Both files means it is ok for all servers and clients to come up
# Neither file means only 1 server should bootstrap, all other servers need to wait for both files
#     and clients need to wait on just .bootstrapped
# having .firstsetup and no .bootstrapped means 1 server is currently bootstrapping so wait on him to finish
if [ -f ${CONSUL_BOOTSTRAP_DIR}/.firstsetup ] && [ -f  ${CONSUL_BOOTSTRAP_DIR}/.bootstrapped ]; then
  # try to converge
  current_acl_agent_token=$(cat ${CONSUL_BOOTSTRAP_DIR}/server_acl_agent_acl_token.json | jq -r -M '.acl_agent_token')

  if [ -z "$CONSUL_ENABLE_ACL" ] || [ "$CONSUL_ENABLE_ACL" -eq "0" ]; then
    if [ -f ${CONSUL_BOOTSTRAP_DIR}/.aclanonsetup ]; then

      echo "WARNING: ACL flag is no longer present, removing the ACL configuration"
      rm -f ${CONSUL_BOOTSTRAP_DIR}/.aclanonsetup \
        ${CONSUL_BOOTSTRAP_DIR}/general_acl_token.json \
        ${CONSUL_BOOTSTRAP_DIR}/server_acl_master_token.json \
        ${CONSUL_BOOTSTRAP_DIR}/server_acl_agent_acl_token.json
    fi
  elif [ ! -f ${CONSUL_BOOTSTRAP_DIR}/.aclanonsetup ] || \
    [ ! -f ${CONSUL_BOOTSTRAP_DIR}/general_acl_token.json ] ||  \
    [ ! -f ${CONSUL_BOOTSTRAP_DIR}/server_acl_master_token.json ] || \
    [ ! -f ${CONSUL_BOOTSTRAP_DIR}/server_acl_agent_acl_token.json ] || \
    [ -z "${current_acl_agent_token}" ]; then

    echo "WARNING: ACL is missconifgured / outdated"
    echo "Attempting to reconfigure ACL."
    echo "Starting the sever in 'local only' mode, reconfigure the cluster ACL if needed and then start normally"
    docker-entrypoint.sh agent -server=true -bootstrap-expect=1 -datacenter=${CONSUL_DATACENTER} -bind=127.0.0.1 &
      consul_pid="$!"

    echo " ---- waiting for the server to come up - 5 seconds"
    ${CONSUL_SCRIPT_DIR}/wait-for-it.sh --timeout=300 --host=127.0.0.1 --port=8500 --strict -- echo+ " ---- consul found" || (echo "ERROR: Failed to located consul." && exit 1)
    sleep 5s

    echo " ---- continuing to repair the cluster ACL configuration"
    ${CONSUL_SCRIPT_DIR}/server_acl.sh
    kill ${consul_pid}

    echo " ---- wait for the local server (pid: ${consul_pid}) to fully shutdown - 5 seconds"
    sleep 5s
  fi

else
  echo "WARNING: The cluster hasn't been bootstrapped"
  echo "All services (Client and Server) are restricted from starup until the bootstrap process has completed"
  if [ ! -f ${CONSUL_BOOTSTRAP_DIR}/.bootstrapped ]; then
      # This is the first server to start so it will drop .firstsetup to note it is running the
      # bootstrap and the other servers need to wait just like the clients until .bootstrapped is dropped.
      echo "This server will begin the bootstrap process"
      touch ${CONSUL_BOOTSTRAP_DIR}/.firstsetup
    else
      echo "The cluster is currently undergoing the bootstrap process by another service."
      until [ -f ${CONSUL_BOOTSTRAP_DIR}/.bootstrapped ]; do sleep 1;echo ' ---- waiting for the bootstrap process to be completed'; done;
  fi

  ${CONSUL_SCRIPT_DIR}/server_tls.sh `hostname -f`
  ${CONSUL_SCRIPT_DIR}/server_gossip.sh

  echo "Configuring ACL support before we start the server"
  if [ -n "${CONSUL_ENABLE_ACL}" ] && [ ! "${CONSUL_ENABLE_ACL}" -eq "0" ] ; then
  	# this needs to be done before the server starts, we cannot move that into server_acl.sh
  	# locks down our consul server from leaking any data to anybody - full anon block
    echo "{ \"acl\": { \"enabled\": true, \"default_policy\": \"deny\", \"down_policy\": \"deny\" } }" > ${CONSUL_BOOTSTRAP_DIR}/server_acl.json
  fi

  echo "Starting server in bootstrap mode. The ACL will be in legacy mode until a leader is elected."
  echo " --- Server will be started in 'local only' mode to not allow node registering while bootstraping"
  link_config_file server_acl.json
  docker-entrypoint.sh agent -server=true -bootstrap-expect=1 -datacenter=${CONSUL_DATACENTER} -bind=127.0.0.1 &
    consul_pid="$!"

  echo " ---- waiting for the server to come up"
  ${CONSUL_SCRIPT_DIR}/wait-for-it.sh --timeout=300 --host=127.0.0.1 --port=8500 --strict -- echo " ---- consul found" || (echo "ERROR: Failed to locate consul" && exit 1)

  echo " ---- waiting further 20 seconds to ensure a leader has been elected"
  sleep 20s

  echo " ---- continuing the cluster boostraping process"
  ${CONSUL_SCRIPT_DIR}/server_acl.sh

  echo "Shutting down 'local only' server (pid: ${consul_pid}) and then starting usual server"
  kill ${consul_pid}

  echo " ---- wait for the 'local only' server to fully shutdown - 10 seconds"
  sleep 10s

  echo "Informing other services that the cluster bootstrapping proces is complete and the startup restriction has been removed"
  touch ${CONSUL_BOOTSTRAP_DIR}/.bootstrapped
fi

echo "The cluster has been bootstrapped"
echo "Linking bootstrap configuration files to the config folder"
link_config_file tls.json
link_config_file gossip.json
link_config_file server_acl.json
link_config_file server_general_acl_token.json
link_config_file server_acl_master_token.json
link_config_file server_acl_agent_acl_token.json
echo "Generating configuration that needs environment variables expanded into ${CONSUL_CONFIG_DIR}/server.json"
#echo "{\"datacenter\": \"${CONSUL_DATACENTER}\", \"data_dir\": \"${CONSUL_DATA_DIR}\", \"node_name\": \"${NODE_NAME}\", \"bootstrap_expect\": ${NUM_OF_MGR_NODES}}" > ${CONSUL_CONFIG_DIR}/server.json
cat "${CONSUL_BOOTSTRAP_DIR}"/server.json | envsubst > "${CONSUL_CONFIG_DIR}"/server.json


#'{{ GetInterfaceIP \"eth0\" }}'
#'{{ GetAllInterfaces | include "network" "192.168.0.0/16" }}'

echo ">=>=>=>=>=>  Swarm/Node Details  <=<=<=<=<=<"
echo "Number of Manager Nodes: ${NUM_OF_MGR_NODES}"
echo "Node IP: ${NODE_IP}"
echo "Node ID: ${NODE_ID}"
echo "Node Name: ${NODE_NAME}"
echo "Node Is Manager: ${NODE_IS_MANAGER}"

echo "Starting consul server (${CONSUL_HTTP} ${CONSUL_HTTPS}) with the following arguments $@"
exec docker-entrypoint.sh "$@"
