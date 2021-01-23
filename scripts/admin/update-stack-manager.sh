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
cd /tmp/consul/scripts
chmod u+x ./*.sh
./deploy.sh
exit
EOL
chmod u+x update-stack.sh
./update-stack.sh
