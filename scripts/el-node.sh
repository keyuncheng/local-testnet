#!/usr/bin/env bash

source ./scripts/util.sh
set -u +e

cleanup() {
    kill $(jobs -p) 2>/dev/null
}

trap cleanup EXIT

node_index=$1
boot_enode=$2

el_data_dir $node_index
datadir=$el_data_dir
address=$(cat $datadir/address)
port=$(expr $BASE_EL_PORT + $node_index)
rpc_port=$(expr $BASE_EL_RPC_PORT + $node_index)
log_file=$datadir/geth.log

echo "Started the geth node #$node_index which is now listening at port $port and rpc at port $rpc_port. You can see the log at $log_file"
$GETH_CMD \
    --datadir $datadir \
    --authrpc.addr "localhost" \
    --authrpc.port $rpc_port \
    --port $port \
    --bootnodes $boot_enode \
    --networkid $NETWORK_ID \
    --unlock $address \
    --password $ROOT/password \
    < /dev/null > $log_file 2>&1

if test $? -ne 0; then
    node_error "The geth node #$node_index returns an error. The last 10 lines of the log file is shown below.\n\n$(tail -n 10 $log_file)"
    exit 1
fi
