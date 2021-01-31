#!/bin/sh

# Make our stuff available
chmod u+x /etc/scripts/common-functions.sh
source /etc/scripts/common-functions.sh
add_path /etc/scripts
set -e

# Update existing packages
apt-get update

# Add required packages
apt-get -y --no-install-recommends install \
  unzip \
  curl \
  ca-certificates \
  procps \
  less \
  vim \
  jq \
  iputils \
  iproute2 \
  bind-tools \
  gettext \
  openssl \
  lshw

# Add Consul & Consul Template Processor
download_consul
download_consul_template

# Download StyleSheet and Vim startup configuration
curl -fLo /usr/share/nginx/html/stylesheet.css https://raw.githubusercontent.com/samrocketman/jervis-api/gh-pages/1.6/stylesheet.css
curl -fLo ~/.vimrc https://raw.githubusercontent.com/samrocketman/home/master/dotfiles/.vimrc

export CONSUL_IP=$(get_ip_from_name "consul.service.consul")
export CONSUL_HTTP_ADDR=http://${CONSUL_IP}:8500

# Get Docker/Node/Hosting information from the Docker API for use in configuration
hosting_details
log "-----------------------------------------------------------"
log "- Portal Details"
log "-----------------------------------------------------------"
log_detail "Consul Address: ${CONSUL_IP}"
log_detail "Consul HTTP Address: ${CONSUL_HTTP_ADDR}"

run_consul_template /etc/templates/nginx.conf nginx.conf /etc/nginx/conf.d/default.conf "consul lock -name service/portal -shell=false reload nginx -s reload"
run_consul_template /etc/templates/index.html index.html /usr/share/nginx/html/index.html

exec nginx -g 'daemon off;'
