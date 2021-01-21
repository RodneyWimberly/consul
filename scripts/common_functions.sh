#!/bin/sh

cmdname=$(basename $0)

function add_path() {
  export PATH=$1:${PATH}
  log "PATH has been updated to ${PATH}"
}

function log() {
    if [[ $QUIET -ne 1 ]]; then echo "$cmdname: $1"; fi
}

function log_detail() {
    if [[ $QUIET -ne 1 ]]; then echo " ---> $cmdname: $1"; fi
}

function log_error() {
    if [[ $QUIET -ne 1 ]]; then echo "[ERROR]: $cmdname: $1"; fi
}

function log_warning() {
    if [[ $QUIET -ne 1 ]]; then echo "[WARN]: $cmdname: $1"; fi
}

function expand_config_file() {
  if [ -f "${CONSUL_BOOTSTRAP_DIR}/$1" ]; then
    log "Processing ${CONSUL_BOOTSTRAP_DIR}/$1 with variable subsutition to ${CONSUL_CONFIG_DIR}/$1"
    if [ -f "${CONSUL_CONFIG_DIR}/$1" ]; then rm -f "${CONSUL_CONFIG_DIR}/$1"; fi
    cat "${CONSUL_BOOTSTRAP_DIR}/$1" | envsubst > "${CONSUL_CONFIG_DIR}/$1"
  else
    log "${CONSUL_BOOTSTRAP_DIR}/$1 was not found, removing ${CONSUL_CONFIG_DIR}/$1"
    rm -f "${CONSUL_CONFIG_DIR}/$1" > /dev/null
  fi
}

function show_node_details() {
    log ">=>=>=>=>=>  Swarm/Node Details  <=<=<=<=<=<"
    log "Number of Manager Nodes: ${NUM_OF_MGR_NODES}"
    log "Node IP: ${NODE_IP}"
    log "Node ID: ${NODE_ID}"
    log "Node Name: ${NODE_NAME}"
    log "Node Is Manager: ${NODE_IS_MANAGER}"
}

function wait_for_bootstrap_completion() {
    if [ ! -f ${CONSUL_BOOTSTRAP_DIR}/.bootstrapped ]; then
      log_warning "The cluster hasn't been bootstrapped"
      log "All services (Client and Server) are restricted from starup until the bootstrap process has completed"
      until [ -f ${CONSUL_BOOTSTRAP_DIR}/.bootstrapped ]; do sleep 1; log_detail 'Waiting for consul cluster bootstrapping process to be complete'; done;
    fi
}
