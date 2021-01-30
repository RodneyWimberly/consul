#!/bin/sh

# Make our stuff available
source "${CORE_SCRIPT_DIR}"/common-functions.sh
add_path "${CORE_SCRIPT_DIR}"

# Add required packages
download_required_packages

# Add Consul & Consul Template Processor
download_consul
download_consul_template

log "Looking up the IP address for Consul to set as Consul domain owner"
CONSUL_IP=
while [ -z "${CONSUL_IP}" ]; do
  log_detail "waiting 2 seconds for Consul to come up and respond on the IP layer"
  sleep 2

  log_detail "querying for service consul.service.consul"
  set +e
  export CONSUL_IP=$(get_ip_from_name "consul.service.consul")
  set -e
done
export CONSUL_HTTP_ADDR=http://${CONSUL_IP}:8500

log_detail "updating configuration based on Consul cluster deployment"
#cat /etc/templates/dnsmasq.conf | envsubst > /etc/dnsmasq/dnsmasq.conf
run_consul_template /etc/templates/dnsmasq.conf dnsmasq.conf /etc/dnsmasq/dnsmasq.conf "consul lock -http-addr=${CONSUL_HTTP_ADDR} -name=service/dnsmasq -shell=false restart killall dnsmasq"

# Get Docker/Node/Hosting information from the Docker API for use in configuration
hosting_details
log "-----------------------------------------------------------"
log "- DNS Details"
log "-----------------------------------------------------------"
log_detail "${CONSUL_DOMAIN} domain downstream DNS: ${CONSUL_IP}"
log_detail "Consul HTTP Address: ${CONSUL_HTTP_ADDR}"

dnsmasq --no-daemon --log-queries --server=/"${CONSUL_DOMAIN}"/"${CONSUL_IP}"#8600
