#!/bin/sh

# Make our stuff available
source "${CORE_SCRIPT_DIR}"/common_functions.sh
add_path "${CORE_SCRIPT_DIR}"

# Update existing packages
apk update

# Add required packages
apk add \
  curl \
  jq \
  iputils \
  iproute2 \
  bind-tools \
  gettext \
  openssl \
  lshw

# this command will automatically register the portal app as a consul service
set -ex
type curl || (
  until apt-get update; do sleep 3; done
  until apt-get -y --no-install-recommends install unzip curl ca-certificates procps less vim; do sleep 3; done
)
curl -fLo /usr/share/nginx/html/stylesheet.css https://raw.githubusercontent.com/samrocketman/jervis-api/gh-pages/1.6/stylesheet.css
curl -fLo ~/.vimrc https://raw.githubusercontent.com/samrocketman/home/master/dotfiles/.vimrc
consul-agent.sh --service '{"service": {"name": "portal", "tags": [], "port": 80}}' \
  --consul-template-file-cmd /nginx.conf nginx.tpl /etc/nginx/conf.d/default.conf "consul lock -name service/portal -shell=false reload nginx -s reload" \
  --consul-template-file /index.html index.html.tpl /usr/share/nginx/html/index.html

# Get Docker/Node/Hosting information from the Docker API for use in configuration
hosting_details

exec nginx -g 'daemon off;'
