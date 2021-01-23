#!/bin/sh

source ../consul.env
source ../common_functions.sh

set -ex

log "Consul Cluster Backup Utility"
backup_file="backup_$(date +%Y-%m-%d-%s).snap"
if [ ! -d backups ]; then; mkdir backups; fi

log_detail "Creating backup file ${backup_file} "
consul_cmd snapshot save "${backup_file}"

log_detail "Coping backup to ./backups/${backup_file}"
docker cp "${consul_container}:${backup_file}" ./backups/
