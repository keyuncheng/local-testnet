#!/usr/bin/env bash

source ./scripts/util.sh
set -u +e

node_index=$1
boot_enode=$2
node_ip=${node_list[$node_index]}

cleanup() {
    ssh $node_ip 'killall geth'
}

trap cleanup EXIT

el_data_dir $node_index
datadir=$el_data_dir
address=$(ssh $node_ip "cat $datadir/address")
port=$(expr $BASE_EL_PORT + $node_index)
rpc_port=$(expr $BASE_EL_RPC_PORT + $node_index)
log_file=$datadir/geth.log

echo "Node $node_index: Started the geth node #$node_index which is now listening at ip $node_ip  port $port and rpc at port $rpc_port. You can see the log at $log_file"
ssh $node_ip "$GETH_CMD \
    --datadir $datadir \
    --authrpc.addr $node_ip \
    --authrpc.port $rpc_port \
    --port $port \
    --bootnodes $boot_enode \
    --networkid $NETWORK_ID \
    --unlock $address \
    --password $ROOT/password \
    < /dev/null > $log_file 2>&1"

if test $? -ne 0; then
    err_logs=$(ssh $node_ip "tail -n 10 $log_file")
    node_error "The geth node #$node_index returns an error. The last 10 lines of the log file is shown below.\n\n$err_logs"
    exit 1
fi
