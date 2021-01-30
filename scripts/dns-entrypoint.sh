#!/bin/sh

# Make our stuff available
source "${CORE_SCRIPT_DIR}"/common-functions.sh
add_path "${CORE_SCRIPT_DIR}"

# Update existing packages
apk update

# Add required packages
apk add --no-cache \
  curl \
  jq \
  iputils \
  iproute2 \
  bind-tools \
  gettext \
  openssl \
  lshw

# Add Consul Template Processor
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

log_detail "merging expanded variables with configuration templates and placing in the config folder"
cat /etc/templates/dnsmasq.conf | envsubst > /etc/dnsmasq/dnsmasq.conf

# Get Docker/Node/Hosting information from the Docker API for use in configuration
hosting_details
log "-----------------------------------------------------------"
log "- DNS Details"
log "-----------------------------------------------------------"
log_detail "${CONSUL_DOMAIN} domain downstream DNS: ${CONSUL_IP}"

dnsmasq --no-daemon --log-queries --server=/"${CONSUL_DOMAIN}"/"${CONSUL_IP}"#8600
