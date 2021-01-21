#!/bin/sh

set -e

if [ -z "$ENABLE_ACL" ] || [ "$ENABLE_ACL" -eq "0" ] ; then
    echo "ACLs is disabled, skipping configuration"
    echo "Creating dummy general_acl_token.json file so the clients can start"

    mkdir -p ${CLIENT_BOOTSTRAP_DIR}
    echo "{}" > ${CLIENT_BOOTSTRAP_DIR}/general_acl_token.json
    exit 0
fi

echo "Configuring ACL security"
# get our one-time boostrap token we can use to generate all other tokens. It can only be done once thus save the token
if [ ! -f ${SERVER_BOOTSTRAP_DIR}/server_acl_master_token.json ]; then
    echo ' ---- The server will remain in ACL Legacy mode unti an election occurs and a leader is chosen.'
    until [ ! -z ${ACL_MASTER_TOKEN} ]; do
        echo " ---- Waiting 1 second before tring to obtain an ACL bootstrap token"
        sleep 1
        echo " ---- Getting ACL bootstrap token / generating master token"
        ACL_MASTER_TOKEN=`curl -sS -X PUT http://127.0.0.1:8500/v1/acl/bootstrap | jq -r -M '.ID'`
    done
    echo "Master token  ${ACL_MASTER_TOKEN} was generated"
	# save our token
	cat > ${SERVER_BOOTSTRAP_DIR}/server_acl_master_token.json <<EOL
{
  "acl_master_token": "${ACL_MASTER_TOKEN}"
}
EOL
fi

${SCRIPT_PATH}/server_acl_server_agent_token.sh
${SCRIPT_PATH}/server_acl_anon.sh
${SCRIPT_PATH}/server_acl_client_general_token.sh
