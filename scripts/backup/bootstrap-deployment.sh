log_detail "Validating swarm network infrastructure"
NET_ID=$(docker network ls -f name=admin_network -q)

if [[ ! -z "$NET_ID" ]]; then
    log_detail "Removing network 'admin_network'"
    docker network rm admin_network

    log_detail "Waiting 5 seconds for network to be removed"
    sleep 5
fi
