#!/bin/sh

if [[ -f ./consul.env ]]; then
  source ./consul.env
elif [[ -f /usr/local/scripts/consul.env ]]; then
  source /usr/local/scripts/consul.env
elif [[ -f /mnt/scripts/consul.env ]]; then
  source /mnt/scripts/consul.env
fi
source "${CONSUL_SCRIPT_DIR}"/common_functions.sh

function configure_acl() {
  log "Starting server in 'local only' mode. The ACL will be in legacy mode until a leader is elected."
  log_detail "Server will be started in 'local only' mode to not allow node registering while bootstrapping"
  docker-entrypoint.sh agent -server=true -bootstrap-expect=1 -datacenter=${CONSUL_DATACENTER} -bind=127.0.0.1 &
    consul_pid="$!"

  log_detail "waiting for the server to come up"
  ${CONSUL_SCRIPT_DIR}/wait-for-it.sh --timeout=300 --host=127.0.0.1 --port=8500 --strict -- echo "consul found" || (echo "Failed to locate consul" && exit 1)

  log_detail "waiting further 15 seconds to ensure a leader has been elected"
  sleep 15s

  log_detail "continuing the cluster bootstrapping process"
  ${CONSUL_SCRIPT_DIR}/bootstrap_acl.sh

  log "Creating Consul cluster backups"
  backup_file="${CONSUL_BOOTSTRAP_DIR}/backup_$(date +%Y-%m-%d-%s).snap"

  log_detail "snapshot will be saved as ${backup_file} "
  ACL_MASTER_TOKEN=`cat ${CONSUL_BOOTSTRAP_DIR}/server_acl_master_token.json | jq -r -M '.acl_master_token'`
  curl -sS --header "X-Consul-Token: ${ACL_MASTER_TOKEN}" http://127.0.0.1:8500/v1/snapshot?dc=docker -o ${backup_file}

  log "Shutting down 'local only' server (pid: ${consul_pid}) and then starting usual server"
  kill ${consul_pid}

  log_detail "wait for the 'local only' server to fully shutdown - 10 seconds"
  sleep 10s

  log_detail "Removing 'local only' configuration and updating it with the newly generated configuration"
  rm -f "${CONSUL_CONFIG_DIR}/server_acl.json"
  cp "${CONSUL_BOOTSTRAP_DIR}/bootstrap.json" "${CONSUL_CONFIG_DIR}/bootstrap.json"

  log_detail "all generated output is being copied to ${CONSUL_BACKUP_DIR}"
  cp -r "${CONSUL_BOOTSTRAP_DIR}/" "${CONSUL_BACKUP_DIR}/"
}

function consul_cmd() (
  consul_container="$(docker stack ps -q -f name=${CONSUL_STACK_PROJECT_NAME}_consul ${CONSUL_STACK_PROJECT_NAME})"
  if [ -z CONSUL_HTTP_TOKEN ] || [ CONSUL_HTTP_TOKEN -eq "0" ]; then
    docker exec "${consul_container}" consul "$@"
  else
    docker exec "${consul_container}" -e CONSUL_HTTP_TOKEN consul "$@"
  fi
)

function consul_api() {
  consul_api_url=http://127.0.0.1:8500/v1/"${1}"

  consul_api_method="${2}"
  if [[ -z "${consul_api_method}" ]]; then
    consul_api_method="GET"
  fi

  consul_api_data=""
  if [[ -z "${3}" ]]; then
    consul_api_data="--data ${3}"
  fi

  current_acl_agent_token=$(cat ${CONSUL_BOOTSTRAP_DIR}/server_acl_agent_acl_token.json | jq -r -M '.acl_agent_token')
  consul_api_token=""
  if [[ -z "${current_acl_agent_token}" ]]; then
    consul_api_token="--header X-Consul-Token: ${current_acl_agent_token}"
  fi
  curl -sS -X "${consul_api_token}" "${consul_api_method}" "${consul_api_data}" "${consul_api_url}"
}

function get_json_property() {
  if [[ -f "$1" ]]; then
    cat "$1" | jq -r -M ".${2}"
  else
    echo "$1" | jq -r -M ".${2}"
  fi
}

function keep_service_alive() {
  while [[ "${CONSUL_KEEP_SERVICE_ALIVE}" -eq "1" ]]; do
    echo "Sleeping so that container will stay running and can be accessed."
    sleep 300
  done
}

function merge_json() {
  generated_json="{}"
  if [ -f ${CONSUL_BOOTSTRAP_DIR}/bootstrap.json ]; then
    generated_json=$(cat ${CONSUL_BOOTSTRAP_DIR}/bootstrap.json)
    rm -f ${CONSUL_BOOTSTRAP_DIR}/bootstrap.json
  fi
  config_json=$(cat ${CONSUL_BOOTSTRAP_DIR}/${1})
  generated_json=$(echo "${generated_json}" | jq ". + ${config_json}")
  log_detail "Adding ${1} to bootstrap.json"
  echo "${generated_json}" | jq ". + ${config_json}" > ${CONSUL_BOOTSTRAP_DIR}/bootstrap.json
}
