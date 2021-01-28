touch ~/update-stack.sh && \
rm ~/update-stack.sh && \
touch ~/update-stack.sh && \
cat > ~/update-stack.sh <<EOL
rm -rf /tmp/consul
git clone -b DeploymentTest \
    https://rodneywimberly:b606a0781f57605d4e5b00b753a6f26c23ff8908@github.com/RodneyWimberly/consul.git \
    /tmp/consul
cp -r /tmp/consul/scripts/* /mnt/scripts/
cp -r /tmp/consul/backups/* /mnt/backups/
cp -r /tmp/consul/certs/* /mnt/certs/
cp -r /tmp/consul/config/* /mnt/config/
chmod u+x /mnt/scripts/*.sh
cd /tmp/consul/scripts
chmod u+x ./*.sh
./deploy.sh
exit
EOL
chmod u+x ~/update-stack.sh
mkdir -p /mnt/backups
mkdir -p /mnt/config
mkdir -p /mnt/certs
mkdir -p /mnt/scripts
mkdir -p /mnt/webmgr
apk add screen git
echo "caption always \"%{= kc}Screen %S on %H system load: %l) %-20=%{= .m}%D %d.%m.%Y %0c\"" > ~/.screenrc
screen -q -t update-stack -S update-stack
./update-stack.sh
