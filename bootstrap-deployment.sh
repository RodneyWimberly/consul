# Install GitHub CLI (curl), Clone Consul repo, and run deployment script.
# This can be used to build application stacks on bare containers

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


apk add git && \
cd /tmp && \
rm -rf /tmp/consul && \
git clone -b DeploymentTest \
    https://rodneywimberly:b606a0781f57605d4e5b00b753a6f26c23ff8908@github.com/RodneyWimberly/consul.git \
    /tmp/consul && \
cd /tmp/consul && \
chmod u+x *.sh && \
chmod u+x ./scripts/*.sh && \
./deploy.sh && \
exit

GITHUB_ACCESS_TOKEN=b606a0781f57605d4e5b00b753a6f26c23ff8908 && \
VERSION=`curl  "https://api.github.com/repos/cli/cli/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | cut -c2-` && \
echo "Downloading GitHub CLI version "$VERSION && \
curl -sSL https://github.com/cli/cli/releases/download/v${VERSION}/gh_${VERSION}_linux_amd64.tar.gz -o gh_${VERSION}_linux_amd64.tar.gz && \
tar xvf gh_${VERSION}_linux_amd64.tar.gz && \
rm gh_${VERSION}_linux_amd64.tar.gz && \
cp gh_${VERSION}_linux_amd64/bin/gh /bin/gh && \
rm -rf ./gh_${VERSION}_linux_amd64 && \
gh version && \
echo "GitHub CLI was successfully installed" && \
echo "${GITHUB_ACCESS_TOKEN}" > key.txt && \
gh auth login --with-token < key.txt && \
rm -rf /tmp/consul && \
echo "Cloning Consul repo" && \
git clone -b DeploymentTest https://rodneywimberly:Mich$11$!@github.com/RodneyWimberly/consul.git /tmp/consul && \
git pull --progress "origin" DeploymentTest:DeploymentTest && \
git clone -b DeploymentTest https://rodneywimberly:b606a0781f57605d4e5b00b753a6f26c23ff8908@github.com/RodneyWimberly/
consul.git /tmp/consul
cd /tmp/consul && \
chmod u+x *.sh && \
chmod u+x ./scripts/*.sh && \
./deploy.sh




