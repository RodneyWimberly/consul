#!/bin/sh

source "${CONSUL_SCRIPT_DIR}"/common_functions.sh
log "Checking current configuration to ensure the cluster is bootstrapped"

## ensure consul is yet not running - important due to supervisor restart
pkill consul

set -e

# Make sure out bootstrap folder exists and permissions are set
mkdir -p ${CONSUL_BOOTSTRAP_DIR}
chown consul:consul ${CONSUL_BOOTSTRAP_DIR}
chown consul:consul ${CONSUL_SCRIPT_DIR}
chmod u+x ${CONSUL_SCRIPT_DIR}/*.sh

if [ -z "${CONSUL_ENABLE_APK}" ]; then
	log "The enable APK flag is disabled, please ensure these dependencies are installed: bash curl jq openssl"
else
	apk update
	apk add bash curl jq openssl gettext
fi

add_path ${CONSUL_SCRIPT_DIR}

# Both files means it is ok for all servers and clients to come up
# Neither file means only 1 server should bootstrap, all other servers need to wait for both files
#     and clients need to wait on just .bootstrapped
# having .firstsetup and no .bootstrapped means 1 server is currently bootstrapping so wait on him to finish
if [ -f ${CONSUL_BOOTSTRAP_DIR}/.firstsetup ] && [ -f  ${CONSUL_BOOTSTRAP_DIR}/.bootstrapped ]; then
  # try to converge
  current_acl_agent_token=$(cat ${CONSUL_BOOTSTRAP_DIR}/server_acl_agent_acl_token.json | jq -r -M '.acl_agent_token')

  if [ -z "$CONSUL_ENABLE_ACL" ] || [ "$CONSUL_ENABLE_ACL" -eq "0" ]; then
    if [ -f ${CONSUL_BOOTSTRAP_DIR}/.aclanonsetup ]; then

      log_warning "ACL flag is no longer present, removing the ACL configuration"
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

    log_warning "ACL is missconifgured / outdated"
    log "Attempting to reconfigure ACL."
    log "Starting the sever in 'local only' mode, reconfigure the cluster ACL if needed and then start normally"
    docker-entrypoint.sh agent -server=true -bootstrap-expect=1 -datacenter=${CONSUL_DATACENTER} -bind=127.0.0.1 &
      consul_pid="$!"

    log_detail "waiting for the server to come up - 5 seconds"
    ${CONSUL_SCRIPT_DIR}/wait-for-it.sh --timeout=300 --host=127.0.0.1 --port=8500 --strict -- echo+ " ---- consul found" || (echo "ERROR: Failed to located consul." && exit 1)
    sleep 5s

    log_detail "continuing to repair the cluster ACL configuration"
    ${CONSUL_SCRIPT_DIR}/server_acl.sh
    kill ${consul_pid}

    log_detail "wait for the local server (pid: ${consul_pid}) to fully shutdown - 5 seconds"
    sleep 5s
  fi

else
  if [ ! -f ${CONSUL_BOOTSTRAP_DIR}/.bootstrapped ]; then
      # This is the first server to start so it will drop .firstsetup to note it is running the
      # bootstrap and the other servers need to wait just like the clients until .bootstrapped is dropped.
      touch ${CONSUL_BOOTSTRAP_DIR}/.firstsetup
      log_warning "The cluster hasn't been bootstrapped"
      log "All services (Client and Server) are restricted from starup until the bootstrap process has completed"
      log "This server will begin the bootstrap process"
    else
      wait_for_bootstrap_completion
  fi

  ${CONSUL_SCRIPT_DIR}/server_tls.sh `hostname -f`
  ${CONSUL_SCRIPT_DIR}/server_gossip.sh

  log "Configuring ACL support before we start the server"
  if [ -n "${CONSUL_ENABLE_ACL}" ] && [ ! "${CONSUL_ENABLE_ACL}" -eq "0" ] ; then
  	# this needs to be done before the server starts, we cannot move that into server_acl.sh
  	# locks down our consul server from leaking any data to anybody - full anon block
    echo "{ \"acl\": { \"enabled\": true, \"default_policy\": \"deny\", \"down_policy\": \"deny\" } }" > ${CONSUL_BOOTSTRAP_DIR}/server_acl.json
  fi

  log "Starting server in bootstrap mode. The ACL will be in legacy mode until a leader is elected."
  log_detail "Server will be started in 'local only' mode to not allow node registering while bootstraping"
  expand_config_file_from server_acl.json
  docker-entrypoint.sh agent -server=true -bootstrap-expect=1 -datacenter=${CONSUL_DATACENTER} -bind=127.0.0.1 &
    consul_pid="$!"

  log_detail "waiting for the server to come up"
  ${CONSUL_SCRIPT_DIR}/wait-for-it.sh --timeout=300 --host=127.0.0.1 --port=8500 --strict -- echo "consul found" || (echo "Failed to locate consul" && exit 1)

  log_detail "waiting further 20 seconds to ensure a leader has been elected"
  sleep 20s

  log_detail "continuing the cluster boostraping process"
  ${CONSUL_SCRIPT_DIR}/server_acl.sh

  log "Shutting down 'local only' server (pid: ${consul_pid}) and then starting usual server"
  kill ${consul_pid}

  log_detail "wait for the 'local only' server to fully shutdown - 10 seconds"
  sleep 10s

  log "Informing other services that the cluster bootstrapping proces is complete and the startup restriction has been removed"
  touch ${CONSUL_BOOTSTRAP_DIR}/.bootstrapped
fi

log "The cluster has been bootstrapped"
log "Linking bootstrap configuration files to the config folder"
expand_config_file_from tls.json
expand_config_file_from common.json
expand_config_file_from server.json
expand_config_file_from gossip.json
expand_config_file_from server_acl.json
expand_config_file_from server_general_acl_token.json
expand_config_file_from server_acl_master_token.json
expand_config_file_from server_acl_agent_acl_token.json

#'{{ GetInterfaceIP \"eth0\" }}'
#'{{ GetAllInterfaces | include "network" "192.168.0.0/16" }}'

show_node_details

log "Starting consul server with the following arguments $@"
exec docker-entrypoint.sh "$@"
