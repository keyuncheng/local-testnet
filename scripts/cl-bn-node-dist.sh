#!/usr/bin/env bash

source ./scripts/util.sh
set -u +e

node_index=$1
node_ip=${node_list[$node_index]}

cleanup() {
    ssh $node_ip "killall $LIGHTHOUSE_CMD 2>/dev/null"
}

trap cleanup EXIT

cl_data_dir $node_index
datadir=$cl_data_dir
port=$(expr $BASE_CL_PORT + $node_index + $node_index)
http_port=$(expr $BASE_CL_HTTP_PORT + $node_index)
log_file=$datadir/beacon_node.log

echo "Node $node_index Started the lighthouse beacon node #$node_index which is now listening at ip $node_ip port $port and http at port $http_port. You can see the log at $log_file"

bootnode_enr=$(ssh $CL_BOOTNODE_IP_ADDR "cat $CL_BOOTNODE_DIR/enr.dat") 

echo "bootnode_enr: $bootnode_enr"

# --disable-packet-filter is necessary because it's involed in rate limiting and nodes per IP limit
# See https://github.com/sigp/discv5/blob/v0.1.0/src/socket/filter/mod.rs#L149-L186
ssh $node_ip "NO_PROXY=\"*\" $LIGHTHOUSE_CMD beacon_node \
    --datadir $datadir \
    --boot-nodes $bootnode_enr \
    --testnet-dir $CONSENSUS_DIR \
    --execution-endpoint http://$node_ip:$(expr $BASE_EL_RPC_PORT + $node_index) \
    --execution-jwt $datadir/jwtsecret \
    --enable-private-discovery \
    --staking \
    --enr-address $node_ip \
    --enr-udp-port $port \
    --enr-tcp-port $(expr $port + 1) \
    --listen-address $node_ip \
    --port $port \
    --http \
    --http-address $node_ip \
    --http-port $http_port \
    --disable-packet-filter \
    < /dev/null > $log_file 2>&1"

    # --debug-level debug \

if test $? -ne 0; then
    node_error "Node $node_index: The lighthouse beacon node #$node_index returns an error. The last 10 lines of the log file is shown below.\n\n$(tail -n 10 $log_file)"
    exit 1
fi
