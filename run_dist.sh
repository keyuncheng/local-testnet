#!/usr/bin/env bash

source ./scripts/util.sh
set -u +e

if ! test $(uname -s) = "Linux"; then
    echo "Only Linux is supported"
fi

check_cmd() {
    if ! command -v $1 >/dev/null; then
        echo -e "\nCommand '$1' not found, please install it first.\n\n$2\n"
        exit 1
    fi
}

if test -e $ROOT; then
    echo "The file $ROOT already exists, please delete or move it first."
    exit 1
fi

# check installation
check_cmd geth "See https://geth.ethereum.org/docs/getting-started/installing-geth for more detail."
check_cmd bootnode "See https://geth.ethereum.org/docs/getting-started/installing-geth for more detail."
check_cmd lighthouse "See https://lighthouse-book.sigmaprime.io/installation.html for more detail."
check_cmd lcli "See https://lighthouse-book.sigmaprime.io/installation-source.html and run \"make install-lcli\"."
check_cmd npm "See https://nodejs.org/en/download/ for more detail."
check_cmd node "See https://nodejs.org/en/download/ for more detail."

cleanup() {
    echo "Shutting down"
    pids=$(jobs -p)
    while ps p $pids >/dev/null 2>/dev/null; do
        kill $pids 2>/dev/null
        sleep 1
    done
    while test -e $ROOT; do
        rm -rf $ROOT 2>/dev/null
        sleep 1
    done
    echo "Deleted the data directory"
}

# cleanup data directory on exit
# trap cleanup EXIT

# All nodes: create data directory
for node_ip in ${node_list[@]}
do
    ssh $node_ip "mkdir -p $ROOT"
done

# Signer node(#0): generate build directory (generate keystore files using ethereum/staking-deposit-cli)
if ! ./scripts/build.sh; then
    echo -e "\n*Failed!* in the build step\n"
    exit 1
fi

# prepare execulation layer nodes (execution clients)
if ! ./scripts/prepare-el-dist.sh; then
    echo -e "\n*Failed!* in the execution layer preparation step\n"
    exit 1
fi
