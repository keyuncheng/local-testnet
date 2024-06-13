#!/usr/bin/env bash

source ./scripts/util.sh
set -eu

mkdir -p $BUILD_DIR

# Generate a dummy password for accounts
echo "adslab" > $ROOT/password

# Download staking-deposit-cli binary exec
if ! test -e $BUILD_DIR/deposit; then
    echo "$BUILD_DIR/deposit not found. Downloading it from https://github.com/ethereum/staking-deposit-cli"

    curl -s -L -o $ROOT/deposit.tar.gz "https://github.com/ethereum/staking-deposit-cli/releases/download/v2.3.0/staking_deposit-cli-76ed782-linux-amd64.tar.gz"
    tar xf $ROOT/deposit.tar.gz -C $ROOT

    mv $ROOT/staking_deposit-cli-76ed782-linux-amd64/deposit $BUILD_DIR/deposit
    rm -rf $ROOT/staking_deposit-cli-76ed782-linux-amd64 $ROOT/deposit.tar.gz

    echo "$BUILD_DIR/deposit downloaded"
fi

# check how many validators keys have been generated
validator_count=0
if test -e $BUILD_DIR/validator_keys; then
    # Check how many validators we have already generated
    validator_count=$(find $BUILD_DIR/validator_keys -name "keystore*" -print | wc -l)
fi

# Generate only for the remaining validators
# We use kiln because we have the same GENESIS_FORK_VERSION which is
# 0x70000069
echo "Generate the credentials for all of $VALIDATOR_COUNT validators"

if test $validator_count -lt $VALIDATOR_COUNT; then
    echo "Generating the credentials for the remaining $(expr $VALIDATOR_COUNT - $validator_count) validators at $BUILD_DIR/validator_keys"

    $BUILD_DIR/deposit \
        --language english \
        --non_interactive \
        existing-mnemonic \
        --num_validators $(expr $VALIDATOR_COUNT - $validator_count)\
        --mnemonic="adslab" \
        --validator_start_index $validator_count \
        --chain kiln \
        --keystore_password $(cat $ROOT/password) \
        --folder $BUILD_DIR

    echo "Done generating the credentials"
fi
