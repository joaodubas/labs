#!/usr/bin/env bash
function create_ca_cert() {
    echo "create ca cert"
    docker-compose run db_one cert create-ca --allow-ca-key-reuse
}

function create_node_cert() {
    local service=${1}
    echo "create node cert for ${service}"
    docker-compose run ${service} cert create-node localhost 127.0.0.1 proxy ${service} --overwrite
    docker-compose run --entrypoint /bin/bash ${service} -c 'cp /certs/ca.crt /certs/node.crt /certs/node.key /cockroach/cert'
}

function create_user_cert() {
    local username=${1}
    echo "create user cert for ${username}"
    docker-compose run db_one cert create-client ${username}
}

create_ca_cert
create_node_cert db_one
create_node_cert db_two
create_node_cert db_three
create_user_cert root
create_user_cert maxroach