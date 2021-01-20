#!/bin/sh

echo "Checking current configuration to ensure the cluster is bootstrapped"

## ensure consul is yet not running - important due to supervisor restart
pkill consul

set -e

mkdir -p ${SERVER_BOOTSTRAP_CONFIG}
mkdir -p ${CLIENTS_BOOTSTRAP_CONFIG}

if [ -z "${ENABLE_APK}" ]; then
	echo "The enable APK flag is disabled, please ensure these dependencies are installed: bash curl jq openssl"
else
	apk update
	apk add bash curl jq openssl
fi

mkdir -p ${SERVER_BOOTSTRAP_CONFIG}

export PATH=/usr/local/bin:${PATH}
echo "Current Path ${PATH}"
export CONSUL_HTTP=http://${NODE_IP}:8500
export CONSUL_HTTPS=https://${NODE_IP}:8501

# Both files means it is ok for all servers and clients to come up
# Neither file means only 1 server should bootstrap, all other servers need to wait for both files
#     and clients need to wait on just .bootstrapped
# having .firstsetup and no .bootstrapped means 1 server is currently bootstrapping so wait on him to finish
if [ -f ${SERVER_BOOTSTRAP_CONFIG}/.firstsetup ] && [ -f  ${CLIENTS_BOOTSTRAP_CONFIG}/.bootstrapped ]; then
  echo "The cluster has been bootstrapped"
  # try to converge
  current_acl_agent_token=$(cat ${SERVER_BOOTSTRAP_CONFIG}/server_acl_agent_acl_token.json | jq -r -M '.acl_agent_token')

  if [ -z "$ENABLE_ACL" ] || [ "$ENABLE_ACL" -eq "0" ]; then
    if [ -f ${SERVER_BOOTSTRAP_CONFIG}/.aclanonsetup ]; then

      echo "WARNING: ACL flag is no longer present, removing the ACL configuration"
      rm -f ${SERVER_BOOTSTRAP_CONFIG}/.aclanonsetup ${CLIENTS_BOOTSTRAP_CONFIG}/general_acl_token.json ${SERVER_BOOTSTRAP_CONFIG}/server_acl_master_token.json ${SERVER_BOOTSTRAP_CONFIG}/server_acl_agent_acl_token.json
    fi
  elif [ ! -f ${SERVER_BOOTSTRAP_CONFIG}/.aclanonsetup ] || [ ! -f ${CLIENTS_BOOTSTRAP_CONFIG}/general_acl_token.json ] ||  [ ! -f ${SERVER_BOOTSTRAP_CONFIG}/server_acl_master_token.json ] || [ ! -f ${SERVER_BOOTSTRAP_CONFIG}/server_acl_agent_acl_token.json ] || [ -z "${current_acl_agent_token}" ]; then

    echo "WARNING: ACL is missconifgured / outdated"
    echo "Attempting to reconfigure ACL."
    echo "Starting the sever in 'local only' mode, reconfigure the cluster ACL if needed and then start normally"
    ${SCRIPT_PATH}/docker-entrypoint.sh "$@" -bind 127.0.0.1 &
    consul_pid="$!"

    echo " ---- waiting for the server to come up - 5 seconds"
    ${SCRIPT_PATH}/wait-for-it -t 300 -h 127.0.0.1 -p 8500 --strict -- echo+ " ---- consul found" || (echo "ERROR: Failed to located consul." && exit 1)
    sleep 5s

    echo " ---- continuing to repair the cluster ACL configuration"
    ${SCRIPT_PATH}/server_acl.sh
    kill ${consul_pid}

    echo " ---- wait for the local server (pid: ${consul_pid}) to fully shutdown - 5 seconds"
    sleep 5s
  fi

else
  echo "WARNING: The cluster hasn't been bootstrapped"
  echo "All services (Client and Server) are restricted from starup until the bootstrap process has completed"
  if [ ! -f ${CLIENTS_BOOTSTRAP_CONFIG}/.bootstrapped ]; then
      # This is the first server to start so it will drop .firstsetup to note it is running the
      # bootstrap and the other servers need to wait just like the clients until .bootstrapped is dropped.
      echo "This server will begin the bootstrap process"
      touch ${SERVER_BOOTSTRAP_CONFIG}/.firstsetup
    else
      echo "The cluster is currently undergoing the bootstrap process by another service."
      until [ -f ${CLIENTS_BOOTSTRAP_CONFIG}/.bootstrapped ]; do sleep 1;echo ' ---- waiting for the bootstrap process to be completed'; done;
  fi

  ${SCRIPT_PATH}/server_tls.sh `hostname -f`
  ${SCRIPT_PATH}/server_gossip.sh

  echo "Configuring ACL support before we start the server"
  if [ -n "${ENABLE_ACL}" ] && [ ! "${ENABLE_ACL}" -eq "0" ] ; then
  	# this needs to be done before the server starts, we cannot move that into server_acl.sh
  	# locks down our consul server from leaking any data to anybody - full anon block
	cat > ${SERVER_BOOTSTRAP_CONFIG}/server_acl.json <<EOL
{
  "acl_datacenter": "stable",
  "acl_default_policy": "deny",
  "acl_down_policy": "deny"
}
EOL
  fi

  echo "Starting server in 'local only' mode to not allow node registering during configuration"
  ${SCRIPT_PATH}/docker-entrypoint.sh "$@" -bind 127.0.0.1 &
  consul_pid="$!"

  echo " ---- waiting for the server to come up"
  ${SCRIPT_PATH}/wait-for-it -t 300 -h 127.0.0.1 -p 8500 --strict -- echo " ---- consul found" || (echo "ERROR: Failed to locate consul" && exit 1)

  echo " ---- waiting further 15 seconds to ensure our server is fully bootstrapped"
  sleep 15s

  echo " ---- continuing the cluster boostraping process"
  ${SCRIPT_PATH}/server_acl.sh

  echo "Shutting down 'local only' server (pid: ${consul_pid}) and then starting usual server"
  kill ${consul_pid}

  echo " ---- wait for the 'local only' server to fully shutdown - 10 seconds"
  sleep 10s

  echo "Informing other services that the cluster bootstrapping proces is complete and the startup restriction has been removed"
  touch ${CLIENTS_BOOTSTRAP_CONFIG}/.bootstrapped
fi
echo "Swarm Information: "
echo "Number of Manager Nodes: ${NUM_OF_MGR_NODES}"
echo "Node IP: ${NODE_IP}"
echo "Node ID: ${NODE_ID}"
echo "Node Name: ${NODE_NAME}"
echo "Node Is Manager: ${NODE_IS_MANAGER}"

echo "Starting server ${CONSUL_HTTP} ${CONSUL_HTTPS}"
exec ${SCRIPT_PATH}/docker-entrypoint.sh "$@"
