#!/usr/bin/env bash

source ./scripts/util.sh
set -u +e

cleanup() {
    kill $(jobs -p) 2>/dev/null
}

trap cleanup EXIT

datadir=$1
boot_enode=$2

address=$(cat $datadir/address)
log_file=$datadir/geth.log

echo "Started the geth node 'signer' which is now listening at port $SIGNER_PORT. You can see the log at $log_file"
$GETH_CMD \
    --datadir $datadir \
    --authrpc.addr $SIGNER_IP_ADDR \
    --authrpc.port $SIGNER_RPC_PORT \
    --port $SIGNER_PORT \
    --bootnodes $boot_enode \
    --networkid $NETWORK_ID \
    --unlock $address \
    --password $ROOT/password \
    --allow-insecure-unlock \
    --http \
    --http.port $SIGNER_HTTP_PORT \
    --mine \
    < /dev/null > $log_file 2>&1

if test $? -ne 0; then
    node_error "The geth node 'signer' returns an error. The last 10 lines of the log file is shown below.\n\n$(tail -n 10 $log_file)"
    exit 1
fi
