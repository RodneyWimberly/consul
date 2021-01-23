#!/bin/sh

function consul_cmd() (
  consul_container="$(docker stack ps -q -f name=${CONSUL_STACK_PROJECT_NAME}_consul ${CONSUL_STACK_PROJECT_NAME})"
  if [ -z CONSUL_HTTP_TOKEN ] || [ CONSUL_HTTP_TOKEN -eq "0" ] then;
    docker exec "${consul_container}" consul "$@"
  else
    docker exec "${consul_container}" -e CONSUL_HTTP_TOKEN consul "$@"
  fi
)

function cd_consul() {
  cd "${CONSUL_GIT_DIR}"
}

function consul_git_dir_available() {
  [ -d "${CONSUL_GIT_DIR}" ]
}

function add_path() {
  export PATH=$1:${PATH}
  log "PATH has been updated to ${PATH} "
}

function log() {
    echo "$1"
}

function log_detail() {
    echo " --> $1"
}

function log_error() {
    echo "[ERROR]: $1"
}

function log_warning() {
    echo "[WARN]: $1"
}

function append_generated_config() {
  echo "${1}" >> ${CONSUL_BOOTSTRAP_DIR}/generated.json
  cat ${CONSUL_BOOTSTRAP_DIR}/"${1}" >> ${CONSUL_BOOTSTRAP_DIR}/generated.json
}

function expand_config_file_from() {
  set +e
  log "Processing ${CONSUL_BOOTSTRAP_DIR}/$1 with variable expansion to ${CONSUL_CONFIG_DIR}/$1"
  rm -f "${CONSUL_CONFIG_DIR}/$1"
  cat "${CONSUL_BOOTSTRAP_DIR}/$1" | envsubst > "${CONSUL_CONFIG_DIR}/$1"
  set -e
}

function get_node_details() {
  NODE_INFO=$(curl -sS --unix-socket /var/run/docker.sock http://localhost/info)
  export NUM_OF_MGR_NODES=$(echo ${NODE_INFO} | jq -r -M '.Swarm.Managers')
  export NODE_IP=$(echo ${NODE_INFO} | jq -r -M '.Swarm.NodeAddr')
  export NODE_ID=$(echo ${NODE_INFO} | jq -r -M '.Swarm.NodeID')
  export NODE_NAME=$(echo ${NODE_INFO} | jq -r -M '.Name')
  export NODE_IS_MANAGER=$(echo ${NODE_INFO} | jq -r -M '.Swarm.ControlAvailable')
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
      until [ -f  ${CONSUL_BOOTSTRAP_DIR}/.bootstrapped ]; do
        sleep 1
        log_detail 'Waiting for consul cluster bootstrapping process to be complete'
      done
    fi
}
