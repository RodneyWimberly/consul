#!/bin/sh
set -ex

# Make our stuff available
chmod u+x "${CORE_SCRIPT_DIR}"/common-functions.sh
source "${CORE_SCRIPT_DIR}"/common-functions.sh
add_path "${CORE_SCRIPT_DIR}"

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

# Add Consul Template Processor
download_consul_template

# Download StyleSheet and Vim startup configuration
curl -fLo /usr/share/nginx/html/stylesheet.css https://raw.githubusercontent.com/samrocketman/jervis-api/gh-pages/1.6/stylesheet.css
curl -fLo ~/.vimrc https://raw.githubusercontent.com/samrocketman/home/master/dotfiles/.vimrc
# consul-agent.sh --service '{"service": {"name": "portal", "tags": [], "port": 80}}' \
#   --consul-template-file-cmd /nginx.conf nginx.tpl /etc/nginx/conf.d/default.conf "consul lock -name service/portal -shell=false reload nginx -s reload" \
#   --consul-template-file /index.html index.html.tpl /usr/share/nginx/html/index.html

# Get Docker/Node/Hosting information from the Docker API for use in configuration
hosting_details

exec nginx -g 'daemon off;'
