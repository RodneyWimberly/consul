#!/bin/sh

set -e

if [ -z "${CONSUL_ENABLE_GOSSIP}" ] || [ "${CONSUL_ENABLE_GOSSIP}" -eq "0" ]; then
    echo "GOSSIP is disabled, skipping configuration"
    exit 0
fi

echo "Configuring Gossip encryption"
if [ ! -f ${CONSUL_BOOTSTRAP_DIR}/gossip.json ]; then
    echo "Generating new Gossip Encryption Key"
	GOSSIP_KEY=`consul keygen`
	echo "{\"encrypt\": \"${GOSSIP_KEY}\"}" > ${CONSUL_BOOTSTRAP_DIR}/gossip.json
fi
