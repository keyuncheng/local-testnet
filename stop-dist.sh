#!/usr/bin/env bash

source ./scripts/util.sh
set -u +e -x

for (( node=1; node<=$NODE_COUNT; node++ )); do
    node_ip=${node_list[$node]}
    ssh $node_ip "rm -rf $ROOT"
    ssh $node_ip "killall geth lighthouse 2>/dev/null"
done

rm -rf $ROOT
killall bootnode geth lighthouse lcli 2>/dev/null

