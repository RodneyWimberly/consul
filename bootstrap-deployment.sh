# Install GitHub CLI (curl), Clone Consul repo, and run deployment script.
# This can be used to create a script on the PWD jump box that
# gets the latest version from source control and calls deploy.sh

# Manager script
touch update-stack.sh && \
rm update-stack.sh && \
touch update-stack.sh && \
cat > update-stack.sh <<EOL
apk add git
cd /tmp
rm -rf /tmp/consul
git clone -b DeploymentTest \
      \
    /tmp/consul
cd /tmp/consul
chmod u+x *.sh
chmod u+x ./scripts/*.sh
./deploy.sh
exit
EOL
chmod u+x update-stack.sh

# Worker Script
touch update-stack.sh && \
rm update-stack.sh && \
touch update-stack.sh && \
cat > update-stack.sh <<EOL
apk add git
cd /tmp
rm -rf /tmp/consul
git clone -b DeploymentTest \
    https://rodneywimberly:b606a0781f57605d4e5b00b753a6f26c23ff8908@github.com/RodneyWimberly/consul.git \
    /tmp/consul
cd /tmp/consul
chmod u+x *.sh
chmod u+x ./scripts/*.sh
exit
EOL
chmod u+x update-stack.sh



log_detail "Validating swarm network infrastructure"
NET_ID=$(docker network ls -f name=admin_network -q)

if [[ ! -z "$NET_ID" ]]; then
    log_detail "Removing network 'admin_network'"
    docker network rm admin_network

    log_detail "Waiting 5 seconds for network to be removed"
    sleep 5
fi
