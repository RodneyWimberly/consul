#!/bin/sh

echo "Starting Consul server, please wait..."

## ensure consul is yet not running - important due to supervisor restart
pkill consul

set -e

mkdir -p ${SERVER_CONFIG_STORE}
mkdir -p ${CLIENTS_SHARED_CONFIG_STORE}

#if [ -f ${SERVER_CONFIG_STORE}/.firstsetup ]; then
#	touch ${CLIENTS_SHARED_CONFIG_STORE}/.bootstrapped
#
#	# this is a moveable pointer, so in 2023 we will use .updatecerts2018 to regenerate all certificates since tey are valid for 5 years only
#	if [ ! -f ${SERVER_CONFIG_STORE}/.updatecerts2018 ]; then
#        server_tls.sh `hostname -f`
#	    touch ${SERVER_CONFIG_STORE}/.updatecerts2018
#    fi
#fi

if [ -z "${ENABLE_APK}" ]; then
	echo "disabled apk, hopefully you got all those things installed: bash curl jq openssl"
else
	apk update
	apk add bash curl jq openssl
fi

mkdir -p ${SERVER_CONFIG_STORE}

echo "**** >=>=>=>  Hosting Details  <=<=<=< ****"
echo "Number of Manager Nodes: ${NUM_OF_MGR_NODES}"
echo "Node IP: ${NODE_IP}"
echo "Node ID: ${NODE_ID}"
echo "Node Name: ${NODE_NAME}"
echo "Node Is Manager: ${NODE_IS_MANAGER}"
echo "*******************************************"

#export PATH=/usr/local/bin:${PATH}
export CONSUL_HTTP=http://${NODE_IP}:8500
export CONSUL_HTTPS=https://${NODE_IP}:8501

# Both files means it is ok for all servers and clients to come up
# Neither file means only 1 server should bootstrap, all other servers need to wait for both files
#     and clients need to wait on just .bootstrapped
# having .firstsetup and no .bootstrapped means 1 server is currently bootstrapping so wait on him to finish
if [ -f ${SERVER_CONFIG_STORE}/.firstsetup ] && [ -f  ${CLIENTS_SHARED_CONFIG_STORE}/.bootstrapped ]; then

  echo "Server already bootstrapped"

  # try to converge
  current_acl_agent_token=$(cat ${SERVER_CONFIG_STORE}/server_acl_agent_acl_token.json | jq -r -M '.acl_agent_token')
  if [ -z "$ENABLE_ACL" ] || [ "$ENABLE_ACL" -eq "0" ]; then
    # deconfigure ACL, no longer present
    rm -f ${SERVER_CONFIG_STORE}/.aclanonsetup ${CLIENTS_SHARED_CONFIG_STORE}/general_acl_token.json ${SERVER_CONFIG_STORE}/server_acl_master_token.json ${SERVER_CONFIG_STORE}/server_acl_agent_acl_token.json
  elif [ ! -f ${SERVER_CONFIG_STORE}/.aclanonsetup ] || [ ! -f ${CLIENTS_SHARED_CONFIG_STORE}/general_acl_token.json ] ||  [ ! -f ${SERVER_CONFIG_STORE}/server_acl_master_token.json ] || [ ! -f ${SERVER_CONFIG_STORE}/server_acl_agent_acl_token.json ] || [ -z "${current_acl_agent_token}" ]; then
    echo "ACL is missconifgured / outdated, trying to fix it"
    # safe start the sever, configure ACL if needed and then start normally
    docker-entrypoint.sh "$@" -bind 127.0.0.1 &
    consul_pid="$!"
    echo "waiting for the server to come up..."
    wait-for-it -t 300 -h 127.0.0.1 -p 8500 --strict -- echo "..consul found" || (echo "error waiting for consul" && exit 1)
    sleep 5s
    server_acl.sh
    kill ${consul_pid}
    echo "wait for the local server to fully shutdown - 5 seconds, pid: ${consul_pid}"
    sleep 5s
  fi

   # normal startup
  exec docker-entrypoint.sh "$@"
else
  if [ -f ${CLIENTS_SHARED_CONFIG_STORE}/.bootstrapped ]; then
    if [ -f ${SERVER_CONFIG_STORE}/.firstsetup ]; then
      # This is the first server to start so it will drop .firstsetup to note it is running the
      # bootstrap and the other servers need to wait just like the clients until .bootstrapped is dropped.
      touch ${SERVER_CONFIG_STORE}/.firstsetup
      echo "--- First bootstrap of the server..configuring ACL/GOSSIP/TLS as configured"
    else
      echo "--- First server is currently botstrapping so wait on them to complete"
      until [ -f ${CLIENTS_SHARED_CONFIG_STORE}/.bootstrapped ]; do sleep 1;echo 'waiting for consul configuration for agent clients to be generated'; done;
    fi
  fi


  server_tls.sh `hostname -f`
  server_gossip.sh

  # enable ACL support before we start the server
  if [ -n "${ENABLE_ACL}" ] && [ ! "${ENABLE_ACL}" -eq "0" ] ; then
  	# this needs to be done before the server starts, we cannot move that into server_acl.sh
  	# locks down our consul server from leaking any data to anybody - full anon block
	cat > ${SERVER_CONFIG_STORE}/server_acl.json <<EOL
{
  "acl_datacenter": "stable",
  "acl_default_policy": "deny",
  "acl_down_policy": "deny"
}
EOL
  fi

  echo "---- Starting server in local 127.0.0.1 to not allow node registering during configuration"
  docker-entrypoint.sh "$@" -bind 127.0.0.1 &
  consul_pid="$!"
  echo "waiting for the server to come up..."
  wait-for-it -t 300 -h 127.0.0.1 -p 8500 --strict -- echo "..consul found" || (echo "error waiting for consul" && exit 1)
  echo "waiting further 15 seconds to ensure our server is fully bootstrapped"
  sleep 15s
  echo "continuing server boostrap after additional 15 seconds passed"
  server_acl.sh
  echo "--- shutting down 'local only' server and starting usual server, pid: ${consul_pid}"
  kill ${consul_pid}

  echo "wait for the local server to fully shutdown - 10 seconds"
  sleep 10s
  # that does secure we do not rerun this initial bootstrap configuration
  #touch ${SERVER_CONFIG_STORE}/.firstsetup

  # tell our clients they can startup, finding the configuration they need on the shared volume
  touch ${CLIENTS_SHARED_CONFIG_STORE}/.bootstrapped
  # touch ${SERVER_CONFIG_STORE}/.updatecerts2018
  exec docker-entrypoint.sh "$@"
fi
