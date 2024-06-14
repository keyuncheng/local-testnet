#!/usr/bin/env bash

source ./scripts/util.sh
set -u +e

cleanup() {
    kill $(jobs -p) 2>/dev/null
}

trap cleanup EXIT

# Start the boot node
echo "Started the geth bootnode which is now listening at :$EL_BOOTNODE_PORT"
bootnode \
    -nodekey $EL_BOOT_KEY_FILE \
    -addr localhost:$EL_BOOTNODE_PORT \
    < /dev/null > $EL_BOOT_LOG_FILE 2>&1

if test $? -ne 0; then
    node_error "The EL bootnode returns an error. The last 10 lines of the log file is shown below.\n\n$(tail -n 10 $EL_BOOT_LOG_FILE)"
    exit 1
fi
