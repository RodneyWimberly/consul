#!/bin/sh

if [[ -f ./consul.env ]]; then
  source ./consul.env
elif [[ -f /usr/local/scripts/consul.env ]]; then
  source /usr/local/scripts/consul.env
elif [[ -f /tmp/consul/scripts/consul.env ]]; then
  source /tmp/consul/scripts/consul.env
fi

function consul_cmd() (
  consul_container="$(docker stack ps -q -f name=${CONSUL_STACK_PROJECT_NAME}_consul ${CONSUL_STACK_PROJECT_NAME})"
  if [ -z CONSUL_HTTP_TOKEN ] || [ CONSUL_HTTP_TOKEN -eq "0" ]; then
    docker exec "${consul_container}" consul "$@"
  else
    docker exec "${consul_container}" -e CONSUL_HTTP_TOKEN consul "$@"
  fi
)

function add_path() {
  export PATH=$1:${PATH}
  log "PATH has been updated to ${PATH} "
}

function docker_api() {
  docker_api_url="http://localhost/${1}"
  docker_api_method="${2}"
  if [[ -z "${docker_api_method}" ]]; then
    docker_api_method="GET"
  fi
  echo "${docker_api_url}"
  echo "${docker_api_method}"
  return $(curl -sS --connect-timeout 180 --unix-socket /var/run/docker.sock -X "${docker_api_method} ${docker_api_url}")
}

function keep_service_alive() {
  while [[ "${CONSUL_KEEP_SERVICE_ALIVE}" -eq "1" ]]; do
    echo "Sleeping so that container will stay running and can be accessed."
    sleep 300
  done
}

function log() {
  log_raw "[INF] $1"
}

function log_detail() {
  log_raw "[DTL]  ====> $1"
}

function log_error() {
  log_raw "[ERR] $1"
}

function log_warning() {
  log_raw "[WAR] $1"
}

function log_debug() {
  if [ ! -z "$CONSUL_DEBUG_LOG" ] && [ "$CONSUL_DEBUG_LOG" -ne "0" ] ; then
    log_raw "[DBG] $1"
  fi
}

function log_json() {
  if [ ! -z "$CONSUL_DEBUG_LOG" ] && [ "$CONSUL_DEBUG_LOG" -ne "0" ] ; then
    echo "1 ${1}"
    echo "2 ${2}"
    pretty_json=$(echo "${2}" | jq)
    echo "JSON ${pretty_json}"
    log_raw "[DBG] $1: ${pretty_json}"
  fi
}

function log_raw() {
  echo "$(timestamp): $1"
}

function timestamp() {
  date +"%T"
}

function merge_json() {
  generated_json="{}"
  if [ -f ${CONSUL_BOOTSTRAP_DIR}/generated.json ]; then
    generated_json=$(cat ${CONSUL_BOOTSTRAP_DIR}/generated.json)
    rm -f ${CONSUL_BOOTSTRAP_DIR}/generated.json
  fi
  config_json=$(cat ${CONSUL_BOOTSTRAP_DIR}/${1})
  generated_json=$(echo "${generated_json}" | jq ". + ${config_json}")
  log_detail "Adding ${1} to generated.json"
  echo "${generated_json}" | jq ". + ${config_json}" > ${CONSUL_BOOTSTRAP_DIR}/generated.json
}

function expand_config_file_from() {
  set +e
  log "Processing ${CONSUL_BOOTSTRAP_DIR}/$1 with variable expansion to ${CONSUL_CONFIG_DIR}/$1"
  rm -f "${CONSUL_CONFIG_DIR}/$1"
  cat "${CONSUL_BOOTSTRAP_DIR}/$1" | envsubst > "${CONSUL_CONFIG_DIR}/$1"
  set -e
}

function get_docker_details() {
  #NODE_INFO=$(curl -sS --unix-socket /var/run/docker.sock http://localhost/info)
  docker_api "info"
  NODE_INFO="$?"
  export NUM_OF_MGR_NODES=$(echo ${NODE_INFO} | jq -r -M '.Swarm.Managers')
  export NODE_IP=$(echo ${NODE_INFO} | jq -r -M '.Swarm.NodeAddr')
  export NODE_ID=$(echo ${NODE_INFO} | jq -r -M '.Swarm.NodeID')
  export NODE_NAME=$(echo ${NODE_INFO} | jq -r -M '.Name')
  export NODE_IS_MANAGER=$(echo ${NODE_INFO} | jq -r -M '.Swarm.ControlAvailable')
}

function show_docker_details() {
    log ">=>=>=>=>=>  Swarm/Node Details  <=<=<=<=<=<"
    log "Number of Manager Nodes: ${NUM_OF_MGR_NODES}"
    log "Node IP: ${NODE_IP}"
    log "Node ID: ${NODE_ID}"
    log "Node Name: ${NODE_NAME}"
    log "Node Is Manager: ${NODE_IS_MANAGER}"
}

function wait_for_bootstrap_process() {
  if [ -z "$CONSUL_HTTP_TOKEN" ] || [ "$CONSUL_HTTP_TOKEN" -eq "0" ] ; then
    log_detail 'Waiting 60 seconds before inquiring if the Consul cluster bootstrapping service to be complete'
    sleep 60
    set +e
    echo "Querying all containers"
    docker_api "containers/json?all=true"
    #rest_response=$(curl -sS --connect-timeout 180 --unix-socket /var/run/docker.sock -X GET http://localhost/containers/json?all=true)
    echo "$?"
    echo ""

    echo "Querying containers with a filter"
    docker_api "containers/json?all=true&filters=%7B%22volume%22%3A+%5B%22%2Fusr%2Flocal%2Fbackups%22%5D%7D"
    #rest_response=$(curl -sS --connect-timeout 180 --unix-socket /var/run/docker.sock -X GET http://localhost/containers/json?all=true&filters=%7B%22volume%22%3A+%5B%22%2Fusr%2Flocal%2Fbackups%22%5D%7D)
    echo "$?"
    echo ""

    log_detail "Querying Docker REST API to see if service ${CONSUL_STACK_PROJECT_NAME}_consul-bootstrapper has completed"
    docker_api "containers/${CONSUL_STACK_PROJECT_NAME}_consul-bootstrapper/wait" "POST"
    #rest_response=$(curl -sS --connect-timeout 180 --unix-socket /var/run/docker.sock -X POST http://localhost/containers/${CONSUL_STACK_PROJECT_NAME}_consul-bootstrapper/wait)

    status_code=$(echo $? | jq -r -M '.statuscode')
    error_msg=$(echo $? | jq -r -M '.Error.Message')
    if [ -z "${error_msg}" ]; then
      log_detail "The consul cluster has been successfully bootstrapped."
    else
      log_error "The consul cluster bootstrapping service failed!"
      log_error "Message: ${error_msg}"

      keep_service_alive

      log_error "The process will now exit"
      exit 1
    fi
  else
    log_detail "The master ACL Token is present so skipping the bootstrap process."
    log_json "CONSUL_HTTP_TOKEN" "${CONSUL_HTTP_TOKEN}"
  fi
}

