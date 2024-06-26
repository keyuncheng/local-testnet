#!/usr/bin/env bash

source ./scripts/util.sh
set -eu

# All nodes: create consensus dir
for (( node=0; node<=$NODE_COUNT; node++ )); do
    node_ip=${node_list[$node]}
    ssh $node_ip "mkdir -p $CONSENSUS_DIR"
done

# Node 0: install modules
if ! test -e ./web3/node_modules; then
    echo "The package ./web3 doesn't have node modules installed yet. Installing the node modules now"
    npm --prefix ./web3 install >/dev/null 2>/dev/null
    echo "Node modules are already installed"
fi

# Use the signer node to deploy the deposit contract
output=$(NODE_PATH=./web3/node_modules node ./web3/src/deploy-deposit-contract.js --endpoint $SIGNER_EL_DATADIR/geth.ipc)
address=$(echo "$output" | grep "address" | cut -d ' ' -f 2)
transaction=$(echo "$output" | grep "transaction" | cut -d ' ' -f 2)
block_number=$(echo "$output" | grep "block_number" | cut -d ' ' -f 2)

echo "Deployed the deposit contract of the address $address in the transaction $transaction on the block number $block_number"

echo $address > $ROOT/deposit-address
echo $block_number > $CONSENSUS_DIR/deploy_block.txt

# Node 0: create validator keys in consensus folder
mkdir -p $CONSENSUS_DIR/validator_keys
NODE_PATH=./web3/node_modules node ./web3/src/distribute-validators.js \
    --nc $NODE_COUNT \
    --vc $VALIDATOR_COUNT \
    -d $BUILD_DIR/validator_keys \
    -o $CONSENSUS_DIR/validator_keys \
    > $ROOT/deposit-data.json

echo "Node 0: Sending the deposits to the deposit contract"
NODE_PATH=./web3/node_modules node ./web3/src/transfer-deposit.js \
    --endpoint $SIGNER_EL_DATADIR/geth.ipc \
    --deposit-address $address \
    -f $ROOT/deposit-data.json
echo -e "\n Node 0: Done sending all the deposits to the contract"

cp $CONFIG_TEMPLATE_FILE $CONFIG_FILE
echo "PRESET_BASE: \"$PRESET_BASE\"" >> $CONFIG_FILE
echo "TERMINAL_TOTAL_DIFFICULTY: \"$TERMINAL_TOTAL_DIFFICULTY\"" >> $CONFIG_FILE
echo "MIN_GENESIS_ACTIVE_VALIDATOR_COUNT: \"$VALIDATOR_COUNT\"" >> $CONFIG_FILE
echo "MIN_GENESIS_TIME: \"$(expr $(date +%s) + $GENESIS_DELAY)\"" >> $CONFIG_FILE
echo "GENESIS_DELAY: \"$GENESIS_DELAY\"" >> $CONFIG_FILE
echo "GENESIS_FORK_VERSION: \"$GENESIS_FORK_VERSION\"" >> $CONFIG_FILE

echo "DEPOSIT_CHAIN_ID: \"$NETWORK_ID\"" >> $CONFIG_FILE
echo "DEPOSIT_NETWORK_ID: \"$NETWORK_ID\"" >> $CONFIG_FILE
echo "DEPOSIT_CONTRACT_ADDRESS: \"$address\"" >> $CONFIG_FILE

echo "SECONDS_PER_SLOT: \"$SECONDS_PER_SLOT\"" >> $CONFIG_FILE
echo "SECONDS_PER_ETH1_BLOCK: \"$SECONDS_PER_ETH1_BLOCK\"" >> $CONFIG_FILE

echo "Generated $CONFIG_FILE"

# Node 0: Listens to the eth1 chain and finds the genesis beacon state
NO_PROXY=$CL_BOOTNODE_IP_ADDR lcli eth1-genesis \
    --spec $PRESET_BASE \
    --eth1-endpoints http://$SIGNER_IP_ADDR:$SIGNER_HTTP_PORT \
    --testnet-dir $CONSENSUS_DIR 2>/dev/null

echo "Node 0: Generated $CONSENSUS_DIR/genesis.ssz"

NO_PROXY=$CL_BOOTNODE_IP_ADDR lcli \
	generate-bootnode-enr \
	--ip $CL_BOOTNODE_IP_ADDR \
	--udp-port $CL_BOOTNODE_PORT \
	--tcp-port $CL_BOOTNODE_PORT \
	--genesis-fork-version $GENESIS_FORK_VERSION \
	--output-dir $CL_BOOTNODE_DIR

bootnode_enr=$(cat $CL_BOOTNODE_DIR/enr.dat)
echo "- $bootnode_enr" > $CONSENSUS_DIR/boot_enr.yaml
echo "Generated $CONSENSUS_DIR/boot_enr.yaml"

echo "Importing the keystores of the validators to the lighthouse data directories"
for (( node=1; node<=$NODE_COUNT; node++ )); do
    cl_data_dir $node
    el_data_dir $node
    node_ip=${node_list[$node]}
    
    ssh $node_ip "mkdir -p $cl_data_dir"
    ssh $node_ip "cp $el_data_dir/geth/jwtsecret $cl_data_dir"
    
    # copy keys from $CONSENSUS_DIR
    ssh $node_ip "mkdir -p $CONSENSUS_DIR/validator_keys"
    scp -r $CONSENSUS_DIR/validator_keys/node$node $node_ip:$CONSENSUS_DIR/validator_keys
    scp $CONSENSUS_DIR/deploy_block.txt $node_ip:$CONSENSUS_DIR
    scp $CONFIG_FILE $node_ip:$CONSENSUS_DIR

    ssh $node_ip "$LIGHTHOUSE_CMD \
        --testnet-dir $CONSENSUS_DIR \
        account validator import \
        --directory $CONSENSUS_DIR/validator_keys/node$node \
        --datadir $cl_data_dir \
        --password-file $ROOT/password \
        --reuse-password 2>/dev/null"
    echo -n "."
done
echo -e "\nDone importing the keystores"
