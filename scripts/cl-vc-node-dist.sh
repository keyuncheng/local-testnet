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
log_file=$datadir/validator_client.log

echo "Node $node_index: Started the lighthouse validator client #$node_index. You can see the log at $log_file"

# Send all the fee to the PoA signer
ssh $node_ip "NO_PROXY=\"*\" $LIGHTHOUSE_CMD validator_client \
    --datadir $datadir \
    --testnet-dir $CONSENSUS_DIR \
    --init-slashing-protection \
    --beacon-nodes http://$node_ip:$(expr $BASE_CL_HTTP_PORT + $node_index) \
    --suggested-fee-recipient $(ssh $SIGNER_IP_ADDR "cat $SIGNER_EL_DATADIR/address") \
    --debug-level debug \
    < /dev/null > $log_file 2>&1"

if test $? -ne 0; then
    node_error "The lighthouse validator client #$node_index returns an error. The last 10 lines of the log file is shown below.\n\n$(tail -n 10 $log_file)"
    exit 1
fi
