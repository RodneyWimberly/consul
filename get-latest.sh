#!/bin/bash

set -e

source ./scripts/consul.env

cd /tmp/consul
git pull --progress "origin" DeploymentTest:DeploymentTest
chmod u+x *.sh
chmod u+x ./scripts/*.sh
./deploy.sh
