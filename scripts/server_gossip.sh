#!/bin/sh

set -e

if [ -z "${ENABLE_GOSSIP}" ] || [ "${ENABLE_GOSSIP}" -eq "0" ]; then
    echo "GOSSIP is disabled, skipping configuration"
    exit 0
fi

echo "Enabling Gossip encryption"
if [ ! -f ${SERVER_BOOTSTRAP_CONFIG}/gossip.json ]; then
    echo "Generating new Gossip Encryption Key"
	GOSSIP_KEY=`consul keygen`
	echo "{\"encrypt\": \"${GOSSIP_KEY}\"}" > ${SERVER_BOOTSTRAP_CONFIG}/gossip.json
fi
cp ${SERVER_BOOTSTRAP_CONFIG}/gossip.json ${CLIENTS_BOOTSTRAP_CONFIG}/gossip.json
