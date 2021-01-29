#!/bin/sh
set -ex
export IP=$$(ip -o ro get $$(ip ro | awk '$$1 == "default" { print $$3 }') | awk '{print $$5}')
export VAULT_API_ADDR="http://$${IP}:8200" VAULT_CLUSTER_ADDR="https://$${IP}:8201"
exec vault server -config=/vault/config
