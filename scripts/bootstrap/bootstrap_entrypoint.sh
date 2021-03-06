#!/bin/sh

source "${CORE_SCRIPT_DIR}"/core.env
source "${CORE_SCRIPT_DIR}"/bootstrap_functions.sh
source "${CORE_SCRIPT_DIR}"/common-functions.sh

log "Bootstrapping the current cluster, Please Wait..."

pkill consul

set -e

add_path ${CORE_SCRIPT_DIR}

current_acl_agent_token=
if [[ -f "${CONSUL_CONFIG_DIR}/server.json" ]]; then
  current_acl_agent_token=$(cat ${CONSUL_CONFIG_DIR}/server.json | jq -r -M '.acl_agent_token')
fi

if [ -z "${current_acl_agent_token}" ] && [ -f  ${CONSUL_BOOTSTRAP_DIR}/cluster.bootstrapped ]; then
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

    log_warning "ACL is misconfigured / outdated"
    configure_acl
  else
    log_detail "Cluster has already been bootstrapped and is correctly configured."
  fi
else
  ${CORE_SCRIPT_DIR}/bootstrap_tls.sh `hostname -f`
  ${CORE_SCRIPT_DIR}/bootstrap_gossip.sh

  configure_acl

  log "Updating db that the cluster bootstrapping process is complete and the startup restriction has been removed"
  touch ${CONSUL_BOOTSTRAP_DIR}/cluster.bootstrapped
fi
