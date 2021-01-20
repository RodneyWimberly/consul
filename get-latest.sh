#!/bin/bash

set -e

source ./scripts/consul.env

cd /tmp
rm -rf /tmp/consul
git clone -b DeploymentTest \
    https://rodneywimberly:b606a0781f57605d4e5b00b753a6f26c23ff8908@github.com/RodneyWimberly/consul.git \
    /tmp/consul
cd /tmp/consul
chmod u+x *.sh
chmod u+x ./scripts/*.sh
./deploy.sh
