#!/usr/bin/env bash

source ./scripts/util.sh
set -eu

# All nodes: create exec dir
for (( node=0; node<=$NODE_COUNT; node++ )); do
    node_ip=${node_list[$node]}
    ssh $node_ip "mkdir -p $EXECUTION_DIR"
done

new_account_dist() {
    local node=$1
    local datadir=$2
    local node_ip=$3
    
    # Generate a new account for each geth node.
    # $address is the geth generated public key for the account
    # address=$($GETH_CMD --datadir $datadir account new --password $ROOT/password 2>/dev/null | grep -o "0x[0-9a-fA-F]*")
    address=$(ssh $node_ip "$GETH_CMD --datadir $datadir account new --password $ROOT/password 2>/dev/null" | grep -o "0x[0-9a-fA-F]*")
    echo "Node $node: Generated an account with address $address for geth node $node and saved it at $datadir"

    # save the address to data_dir/address
    ssh $node_ip "echo $address > $datadir/address"

    # Add the account into the genesis state
    # Each account is pre-assigned with $INITIAL_BALANCE ETH
    alloc=$(echo $genesis | jq ".alloc + { \"${address:2}\": { \"balance\": \"$INITIAL_BALANCE\" } }")

    # update the genesis block (in json) in $genesis iteratively
    genesis=$(echo $genesis | jq ". + { \"alloc\": $alloc }")
}

genesis=$(cat $GENESIS_TEMPLATE_FILE)

# create $NODE_COUNT of execution client accounts
for (( node=1; node<=$NODE_COUNT; node++ )); do
    # assign $el_data_dir as the node directory
    el_data_dir $node
    node_ip=${node_list[$node]}
    # add new account for the node
    new_account_dist "#$node" $el_data_dir $node_ip
done

# Node 0: create signer account
new_account_dist "'signer'" $SIGNER_EL_DATADIR ${node_list[0]}

# Add the extradata (pad with $1 of zeros)
zeroes() {
    for i in $(seq $1); do
        echo -n "0"
    done
}

# create extra data (some strings) in the genesis block
address=$(cat $SIGNER_EL_DATADIR/address)
extra_data="0x$(zeroes 64)${address:2}$(zeroes 130)"
genesis=$(echo $genesis | jq ". + { \"extradata\": \"$extra_data\" }")

config=$(echo $genesis | jq ".config + { \"chainId\": "$NETWORK_ID", \"terminalTotalDifficulty\": "$TERMINAL_TOTAL_DIFFICULTY", \"clique\": { \"period\": "$SECONDS_PER_ETH1_BLOCK", \"epoch\": 30000 } }")
genesis=$(echo $genesis | jq ". + { \"config\": $config }")

# All nodes: Generate the genesis state (genesis block)
echo $genesis > $GENESIS_FILE
for (( node=1; node<=$NODE_COUNT; node++ )); do
    node_ip=${node_list[$node]}
    scp $GENESIS_FILE $node_ip:$EXECUTION_DIR
done
echo "Generated genesis block file $GENESIS_FILE"

# Node #1-#NODE_COUNT Initialize the geth nodes' directories
for (( node=1; node<=$NODE_COUNT; node++ )); do
    node_ip=${node_list[$node]}
    el_data_dir $node
    datadir=$el_data_dir

    ssh $node_ip "$GETH_CMD init --datadir $datadir $GENESIS_FILE 2>/dev/null"
    echo "Node $node: Initialized the data directory $datadir with $GENESIS_FILE"
done

# Node #0: signer node
$GETH_CMD init --datadir $SIGNER_EL_DATADIR $GENESIS_FILE 2>/dev/null
echo "Node 0: Initialized the data directory $SIGNER_EL_DATADIR with $GENESIS_FILE"

# Node #0: Generate the boot node key
bootnode -genkey $EL_BOOT_KEY_FILE
echo "Node 0: Generated $EL_BOOT_KEY_FILE"
