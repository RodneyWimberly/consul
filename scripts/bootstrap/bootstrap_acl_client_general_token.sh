#!/bin/sh

set -e
source "${CORE_SCRIPT_DIR}"/bootstrap_functions.sh
source "${CORE_SCRIPT_DIR}"/common-functions.sh

# generates an acl_token with all usual ops a agent client need to fully utilize the consul server
# stores it on a share volume so it can be consumed by out consul agent clients
mkdir -p ${CONSUL_BOOTSTRAP_DIR}

if [ ! -f ${CONSUL_BOOTSTRAP_DIR}/general_acl_token.json ]; then
    log "Configuring consul client ACL token for usual access"
    ACL_MASTER_TOKEN=`cat ${CONSUL_BOOTSTRAP_DIR}/server_acl_master_token.json | jq -r -M '.acl_master_token'`

    # this generates a token for all our agent clients to register with the server, write kvs and register services
    ACL_TOKEN=`curl -sS -X PUT --header "X-Consul-Token: ${ACL_MASTER_TOKEN}" \
        --data \
    '{
      "Name": "GENERAL_ACL_TOKEN",
      "Type": "client",
      "Rules": "agent \"\" { policy = \"write\" } event \"\" { policy = \"read\" } key \"\" { policy = \"write\" } node \"\" { policy = \"write\" } service \"\" { policy = \"write\" } operator = \"read\""
    }' http://127.0.0.1:8500/v1/acl/create | jq -r -M '.ID'`

    # let the consul server properly adjust that this ACL exist - when we write the token below all our clients start to boot
    #sleep 1
    # echo "Agent client token: ${AGENT_CLIENT_TOKEN}"
    echo "{\"acl_token\": \"${ACL_TOKEN}\"}" > ${CONSUL_BOOTSTRAP_DIR}/general_acl_token.json
    merge_json "general_acl_token.json"
else
    log "Skipping acl_token setup .. already configured";
fi


