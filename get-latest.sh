#!/bin/bash

set -e

source ./scripts/consul.env

echo "${GITHUB_ACCESS_TOKEN}" > key.txt
gh auth login --with-token < key.txt
rm -rf /tmp/consul
echo "Cloning Consul repo"
rm -rf /tmp/consul
gh repo clone RodneyWimberly/consul /tmp/consul -b DevelopmentTest
cd /tmp/consul
chmod u+x *.sh
chmod u+x ./scripts/*.sh
./deploy.sh
