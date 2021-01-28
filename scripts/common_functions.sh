#!/bin/sh

if [[ -f ./consul.env ]]; then
  source ./consul.env
elif [[ -f /usr/local/scripts/consul.env ]]; then
  source /usr/local/scripts/consul.env
elif [[ -f /tmp/consul/scripts/consul.env ]]; then
  source /tmp/consul/scripts/consul.env
fi

function show_docker_details() {
    log ">=>=>=>=>=>  Swarm/Node Details  <=<=<=<=<=<"
    log "Number of Manager Nodes: ${NUM_OF_MGR_NODES}"
    log "Node IP: ${NODE_IP}"
    log "Node ID: ${NODE_ID}"
    log "Node Name: ${NODE_NAME}"
    log "Node Is Manager: ${NODE_IS_MANAGER}"
}

# G.et J.SON V.alue
function gjv() {
  if [[ -f "${2}" ]]; then
    cat "${2}" | jq -r -M '."${1}"'
  else
    echo "${2}" | jq -r -M '."${1}"'
  fi
}

# S.et J.SON V.alue
function sjv() {
  if [[ -f "${3}" ]]; then
    cat "${3}" | jq ". + { \"${1}\": \"${2}\" }" > "${3}"
  else
    echo "${3}" | jq ". + { \"${1}\": \"${2}\" }" > "${3}"
  fi
}

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

  curl -sS --connect-timeout 180 --unix-socket /var/run/docker.sock -X "${docker_api_method}" "${docker_api_url}"
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

function log_raw() {
  echo "$(date +"%T"): $1"
}

function expand_config_file_from() {
  set +e
  log "Processing ${CONSUL_BOOTSTRAP_DIR}/$1 with variable expansion to ${CONSUL_CONFIG_DIR}/$1"
  rm -f "${CONSUL_CONFIG_DIR}/$1"
  cat "${CONSUL_BOOTSTRAP_DIR}/$1" | envsubst > "${CONSUL_CONFIG_DIR}/$1"
  set -e
}

function restore_snapshot() {
  if [[ "${NODE_IS_MANAGER}" == "true" ]]; then
    if [[ -f "${1}" ]]; then
      log "Restoring cluster snapshot"
      log_detail "Starting server in 'local only' mode to not allow nodes joining the cluster during snapshot restoration"
      echo "{ \"acl\": { \"enabled\": true, \"default_policy\": \"deny\", \"down_policy\": \"deny\" } }" > ${CONSUL_BOOTSTRAP_DIR}/server_acl.json
      merge_json "server_acl.json"
      cp "${CONSUL_BOOTSTRAP_DIR}/server_acl.json" "${CONSUL_CONFIG_DIR}/server_acl.json"
      docker-entrypoint.sh agent -server=true -bootstrap-expect=1 -datacenter=${CONSUL_DATACENTER} -bind=127.0.0.1 &
        consul_pid="$!"

      log_detail "waiting for the server to come up"
      "${CONSUL_SCRIPT_DIR}"/wait-for-it.sh --timeout=300 --host=127.0.0.1 --port=8500 --strict -- echo "consul found" || (echo "Failed to locate consul" && exit 1)

      log_detail "server is responding, waiting further 15 seconds to allow initialization"
      sleep 15s

      log_detail "restoring snapshot '${1}'"
      curl --request PUT --data-binary @"${1}" -sS --header "X-Consul-Token: ${CONSUL_HTTP_TOKEN}" http://127.0.0.1:8500/v1/snapshot

      log "Shutting down 'local only' server (pid: ${consul_pid}) and then starting usual server"
      kill ${consul_pid}

      log_detail "wait for the 'local only' server to fully shutdown - 5 seconds"
      sleep 5s

      log_detail "removing 'local only' configuration for normal startup"
      rm -f "${CONSUL_CONFIG_DIR}/server_acl.json"
    else
      log_warning "snapshot '"${1}"' could be found"
    fi
  else
    log "Snapshots can only be restored from a server/node manager."
  fi
}

