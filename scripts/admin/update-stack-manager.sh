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
cp -r /tmp/consul/scripts/* /mnt/scripts/
cp -r /tmp/consul/backups/* /mnt/backups/
cp -r /tmp/consul/certs/* /mnt/certs/
cp -r /tmp/consul/config/* /mnt/config/
cd /tmp/consul/scripts
chmod u+x ./*.sh
./deploy.sh
exit
EOL
chmod u+x update-stack.sh
mkdir -p /mnt/backups
mkdir -p /mnt/config
mkdir -p /mnt/certs
mkdir -p /mnt/scripts
./update-stack.sh
