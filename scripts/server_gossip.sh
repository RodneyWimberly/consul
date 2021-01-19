#!/bin/sh

set -e

# locks down our consul server from leaking any data to anybody - full anon block

if [ -z "${ENABLE_GOSSIP}" ] || [ "${ENABLE_GOSSIP}" -eq "0" ]; then
    echo "GOSSIP is disabled, skipping configuration"
    exit 0
fi

echo "enable gossip encryption"

if [ ! -f ${SERVER_BOOTSTRAP_CONFIG}/gossip.json ]; then
	GOSSIP_KEY=`consul keygen`
	echo "{\"encrypt\": \"${GOSSIP_KEY}\"}" > ${SERVER_BOOTSTRAP_CONFIG}/gossip.json
	cp ${SERVER_BOOTSTRAP_CONFIG}/gossip.json ${CLIENTS_BOOTSTRAP_CONFIG}/gossip.json
else
	cp ${SERVER_BOOTSTRAP_CONFIG}/gossip.json ${CLIENTS_BOOTSTRAP_CONFIG}/gossip.json
fi
