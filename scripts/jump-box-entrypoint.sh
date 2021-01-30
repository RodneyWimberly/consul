#!/bin/sh

set +e
source "${CORE_SCRIPT_DIR}"/common_functions.sh

apk update
apk add \
  bash \
  curl \
  jq \
  gettext \
  iputils \
  nfs-utils \
  bash \
  iproute2 \
  bind-tools \
  openssl \
  sudo \
  openrc \
  lshw

apk add curl jq openssl gettext iputils nfs-utils iproute2 sudo
sudo -u root mount -v -o vers=4,loud nfsserver_storage:/ /mnt/svc
sudo -u root mount -v -o vers=4,loud 192.168.100.100:/ /mnt/ip
sudo -u root mount -v -o vers=4,loud storage.service.consul:/ /mnt/fqdn
sudo -u root mount -v -o vers=4,loud tasks.nfsserver_storage:/ /mnt/fqdn
sudo -u root mount -v -o vers=4,loud storage:/ /mnt/fqdn
df -h

# Get Docker/Node/Hosting information from the Docker API for use in configuration
hosting_details

exec sh -c 'while true ;do wait ;done'
#while true; do :; done & kill -STOP $! && wait $!
#tail -f /dev/null
# while [[ "true" == "true" ]]; do
#     log "Sleeping 300 seconds so container task won't complete"
#     sleep 300
# done
