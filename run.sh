#!/usr/bin/env bash

set -e

log() {
    echo ">>> $*"
}

pause() {
    t=$1
    shift
    log "waiting ${t}s $*..."
    sleep $t
}

compose() {
    docker-compose $*
}

clean_up() {
    log "cleaning up..."
    compose down --volumes --remove-orphans --timeout 1
}

start_nodes() {
    log "starting nodes $*..."
    compose pull $*
    compose up --detach $*
    pause 5 "nodes to start"case
}

start_endorser() {
    NODE=$1 compose up --detach endorser
}

node_curl() {
    NODE=$1 URL=$2 compose run -T --rm curl
}

get_ips() {
    docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(compose ps -q $@)
}

initialize_sandbox() {
    log "initializing sandbox parameters..."
    compose up initialize-sandbox
}

connect() {
    node=$1
    shift
    addrs=$(get_ips $*)
    log "connecting $node with $* ($addrs)..."
    NODE=$node ADDRS=$addrs compose up connect-nodes
}

generate_accounts() {
    log "generating accounts..."
    node=$1
    accs="$*"
    NODE=$node ACCS="$accs" compose up gen-keys
    compose up gen-parameters
}

initialize_protocol() {
    log "initializing protocol..."
    NODE="$1" compose up initialize-protocol
}

check_mempool() {
    log "checking mempool..."
    operations=$(node_curl "$1" /chains/main/mempool/pending_operations)
    applied=$(echo $operations | jq '.applied | length')
    [ "$applied" -eq 1 ]
}

check_mempool_retries() {
    for i in $(seq 1 $2); do
        sleep 1
        check_mempool $1 && return
        log "$i failed"
    done
    log "$2 attempts failed"
    exit 1
}

bake() {
    log "baking by $*"
    compose up $*
}

head() {
    node_curl $1 /chains/main/blocks/head/header | jq -r '"\(.hash) \(.level)"'
}

head_hash() {
    node_curl $1 /chains/main/blocks/head/header | jq -r .hash
}

NODE=${1:-tezedge-node}
clean_up
initialize_sandbox
start_nodes $NODE node-1 node-2

generate_accounts $NODE acc1 acc2 acc3
initialize_protocol $NODE
connect node-1 $NODE
connect node-2 $NODE

pause 3 "starting endorser"
start_endorser $NODE
pause 3 "after endorser started"


level=2

while [ "$level" -lt 10 ]; do
    pause 10 "before baking level $level"
    bake baker-1 baker-2
    log "heads of the nodes --\\"
    for node in $NODE node-1 node-2; do
        echo "$node: $(head $node)"
    done

    check_mempool_retries $NODE 3
    level=$((level+1))

    pause 10 "before baking level $level"
    bake baker-1
    log "heads of the nodes --\\"
    for node in $NODE node-1 node-2; do
        log "$node: $(head $node)"
    done
    pause 10 "after baking level $level"
    log "heads of the nodes --\\"
    for node in $NODE node-1 node-2; do
        log "$node: $(head $node)"
    done
    level=$((level+1))
done

log "passed on level $((level-1))"
