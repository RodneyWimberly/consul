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
chmod u+x ./scripts/*.sh
chmod u+x ./scripts/admin/*.sh
chmod u+x ./scripts/bootstrap/*.sh
./scripts/admin/deploy.sh
exit
EOL
chmod u+x update-stack.sh