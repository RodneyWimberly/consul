#!/bin/sh

set +e
source "${CONSUL_SCRIPT_DIR}"/consul.env
source "${CONSUL_SCRIPT_DIR}"/common_functions.sh

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
  openssl

mkdir /mnt
mount -v -o vers=4,loud 192.168.100.4:/ /mnt

while [[ "true" == "true" ]]; do
    log "Sleeping 300 seconds so container task won't complete"
    sleep 300
done
