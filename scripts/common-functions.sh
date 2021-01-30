#!/bin/sh

if [[ -f ./core.env ]]; then
  source ./core.env
elif [[ -f /usr/local/scripts/core.env ]]; then
  source /usr/local/scripts/core.env
elif [[ -f /tmp/consul/scripts/core.env ]]; then
  source /tmp/consul/scripts/core.env
fi

function get_ip_from_adapter() {
  ip -o -4 addr list $1 | head -n1 | awk '{print $4}' | cut -d/ -f1
}

function hostip() {
  ip -o ro get $(ip ro | awk '$1 == "default" { print $3 }') | awk '{print $5}'
}

function get_ip_from_name() {
  dig +short $1 | tail -n1
}

function show_hosting_details() {
  log "-----------------------------------------------------------"
  log "- Swarm Details"
  log "-----------------------------------------------------------"
  log_detail "Node Id: ${NODE_ID}"
  log_detail "Node Name: ${NODE_NAME}"
  log_detail "Node Address: ${NODE_IP}"
  log_detail "Manager Node: ${NODE_IS_MANAGER}"
  log_detail "Manager Node Count: ${NUM_OF_MGR_NODES}"
  log ""
  log "-----------------------------------------------------------"
  log "- Container Details"
  log "-----------------------------------------------------------"
  log_detail "Container Name: ${CONTAINER_NAME}"
  log_detail "Container Address: ${CONTAINER_IP}"
  log ""
  log "-----------------------------------------------------------"
  log "- Network Details"
  log "-----------------------------------------------------------"
  log_detail "eth0 Address: ${ETHO_IP}"
  log_detail "eth1 Address: ${ETH1_IP}"
  log_detail "eth2 Address: ${ETH2_IP}"
  log_detail "eth3 Address: ${ETH3_IP}"
  log_detail "eth4 Address: ${ETH4_IP}"
  log ""
}

function get_hosting_details() {
  NODE_INFO=$(docker_api "info")
  export NUM_OF_MGR_NODES=$(echo ${NODE_INFO} | jq -r -M '.Swarm.Managers')
  export NODE_IP=$( echo ${NODE_INFO} | jq -r -M '.Swarm.NodeAddr')
  export NODE_ID=$(echo ${NODE_INFO} | jq -r -M '.Swarm.NodeID')
  export NODE_NAME=$(echo ${NODE_INFO} | jq -r -M '.Name')
  export NODE_IS_MANAGER=$(echo ${NODE_INFO} | jq -r -M '.Swarm.ControlAvailable')
  export CONTAINER_IP=$(hostip)
  export CONTAINER_NAME=$(hostname)
  export ETHO_IP=$(get_ip_from_adapter eth0)
  export ETH1_IP=$(get_ip_from_adapter eth1)
  export ETH2_IP=$(get_ip_from_adapter eth2)
  export ETH3_IP=$(get_ip_from_adapter eth3)
  export ETH4_IP=$(get_ip_from_adapter eth4)
}

function hosting_details() {
  get_hosting_details
  show_hosting_details
}

# G.et J.SON V.alue
function gjv() {
  if [[ -f "$2" ]]; then
    cat $2 | jq -r -M '.$1'
  else
    echo $2 | jq -r -M '.$1'
  fi
}

# S.et J.SON V.alue
function sjv() {
  if [[ -f "$3" ]]; then
    cat $3 | jq ". + { \"$1\": \"$2\" }" > $3
  else
    echo $3 | jq ". + { \"$1\": \"$2\" }" > $3
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

function run_consul_template() {
  # $1 is the source file
  # $2 is the template file name
  # $3 is the destination
  # $4 is the reload command and may not exist
  template_dir=/etc/template
  if [[ ! -d "${template_dir}" ]]; then
    mkdir $template_dir
  fi
  cp $1 $template_dir/$2
  if [ -z "$4" ]; then
    /bin/sh -c "sleep 30;nohup consul-template -template=$template_dir/$2:$3 -retry 30s -consul-retry -wait 30s -consul-retry-max-backoff=15s &"
  else
    /bin/sh -c "nohup consul-template -template=$template_dir/$2:$3:'$4' -retry 30s -consul-retry -wait 30s -consul-retry-max-backoff=15s &"
  fi
}

function download_consul_template() {
  log "Installing Consul-Template"
  curl -Lo /tmp/consul_template_0.15.0_linux_amd64.zip ${CONSUL_URL}/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip && \
    unzip /tmp/consul_template_0.15.0_linux_amd64.zip && \
    mv consul-template /bin && \
    rm /tmp/consul_template_0.15.0_linux_amd64.zip
}

function download_consul() {
  log "Installing Consul-Template"
  curl --remote-name ${CONSUL_URL}/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip && \
  curl --remote-name ${CONSUL_URL}/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_SHA256SUMS && \
  curl --remote-name ${CONSUL_URL}/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_SHA256SUMS.sig && \
  unzip consul_${CONSUL_VERSION}_linux_amd64.zip && \
  mv consul /usr/bin/ && \
  rm /consul_${CONSUL_VERSION}_linux_amd64.zip && \
  rm /consul_${CONSUL_VERSION}_SHA256SUMS && \
  rm consul_${CONSUL_VERSION}_SHA256SUMS.sig && \
  # tiny smoke test to ensure the binary we downloaded runs
  consul version
}

function download_required_packages() {
  # Update existing packages
  apk update

  # Add required packages
  apk add --no-cache \
    curl \
    jq \
    iputils \
    iproute2 \
    bind-tools \
    gettext
}
