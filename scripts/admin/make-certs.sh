#!/bin/sh

source ../core.env
source ../common-functions.sh

log "Creating cluster TLS certificates and encryption keys."
mkdir ./certs
cd ./certs
rm -f ./*

log_detail "Creating encryption key"
consul keygen > ./encrypt.key
encrypt_key=$(cat ./encrypt.key)

log_detail "Creating CA certificate"
consul tls ca create -domain="${CONSUL_DOMAIN}"

log_detail "Creating server certificates"
consul tls cert create -server -dc="${CONSUL_DATACENTER}" -domain="${CONSUL_DOMAIN}"

log_detail "Creating client certificates"
consul tls cert create -client -dc="${CONSUL_DATACENTER}" -domain="${CONSUL_DOMAIN}"

log_detail "Updating the local CA Authority with our certs"
cp ./consul-agent-ca.pem /usr/local/share/ca-certificates/consul-agent-ca.pem
update-ca-certificates 2>/dev/null || true

log "Updating file permissions for the new certs"
chmod 400 ./*.pem

log "Creating sample common/client/server TLS configuration files"
cat > ./server-tls.json <<EOL
{
    "key_file": "${CONSUL_CERT_DIR}/docker-server-consul-0-key.pem",
    "cert_file": "${CONSUL_CERT_DIR}/docker-server-consul-0.pem"
}
EOL
cat > ./client-tls.json <<EOL
{
    "key_file": "${CONSUL_CERT_DIR}/docker-client-consul-0-key.pem",
    "cert_file": "${CONSUL_CERT_DIR}/docker-client-consul-0.pem"
}
EOL
cat > ./common-tls.json <<EOL
{
    "encrypt": "${encrypt_key}",
    "ca_file": "${CONSUL_CERT_DIR}/consul-agent-ca.pem",
    "ca_path": "${CONSUL_CERT_DIR}",
    "addresses": {
        "http": "0.0.0.0",
        "https": "0.0.0.0"
    },
    "ports": {
        "http": 8500,
        "https": 8501
    }
}
EOL
cd ..
