# Install GitHub CLI (curl), Clone Consul repo, and run deployment script.
# This can be used to create a script on the PWD jump box that
# gets the latest version from source control and calls deploy.sh

touch run-stack.sh && \
rm run-stack.sh && \
touch run-stack.sh && \
cat > run-stack.sh <<EOL
apk add git
cd /tmp
rm -rf /tmp/consul
git clone -b DeploymentTest \
    https://rodneywimberly:b606a0781f57605d4e5b00b753a6f26c23ff8908@github.com/RodneyWimberly/consul.git \
    /tmp/consul
cd /tmp/consul
chmod u+x *.sh
chmod u+x ./scripts/*.sh
./deploy.sh
exit
EOL
chmod u+x run-stack.sh

