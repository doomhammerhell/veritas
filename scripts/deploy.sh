#!/bin/bash
# Deploy Veritas contract to StarkNet
# Usage: ./scripts/deploy.sh <network> <admin_address> <num_options> <commit_dur_secs> <reveal_dur_secs>
#
# Example (testnet, 5 options, 1h commit, 1h reveal):
#   ./scripts/deploy.sh testnet 0xADMIN 5 3600 3600
#
# Prerequisites:
#   - starkli installed (https://github.com/xJonathanLEI/starkli)
#   - STARKNET_ACCOUNT and STARKNET_KEYSTORE env vars set
#   - Contract built with `scarb build`

set -e

NETWORK=${1:?Usage: deploy.sh <network> <admin> <num_options> <commit_dur> <reveal_dur>}
ADMIN=${2:?Missing admin address}
NUM_OPTIONS=${3:?Missing num_options}
COMMIT_DUR=${4:?Missing commit_dur}
REVEAL_DUR=${5:?Missing reveal_dur}

SIERRA="target/dev/veritas_Veritas.contract_class.json"
CASM="target/dev/veritas_Veritas.compiled_contract_class.json"

if [ ! -f "$SIERRA" ]; then
    echo "Contract not built. Run: scarb build"
    exit 1
fi

case $NETWORK in
    testnet)
        RPC="https://starknet-sepolia.public.blastapi.io/rpc/v0_7"
        EXPLORER="https://sepolia.starkscan.co"
        ;;
    mainnet)
        RPC="https://starknet-mainnet.public.blastapi.io/rpc/v0_7"
        EXPLORER="https://starkscan.co"
        ;;
    *)
        echo "Invalid network: $NETWORK (use testnet or mainnet)"
        exit 1
        ;;
esac

echo "Declaring contract on $NETWORK..."
CLASS_HASH=$(starkli declare "$SIERRA" --casm "$CASM" --rpc "$RPC" 2>&1 | grep -oE '0x[0-9a-fA-F]+' | head -1)
echo "Class hash: $CLASS_HASH"

echo "Deploying with: admin=$ADMIN num_options=$NUM_OPTIONS commit_dur=$COMMIT_DUR reveal_dur=$REVEAL_DUR"
CONTRACT_ADDRESS=$(starkli deploy "$CLASS_HASH" \
    "$ADMIN" "$NUM_OPTIONS" "$COMMIT_DUR" "$REVEAL_DUR" \
    --rpc "$RPC" 2>&1 | grep -oE '0x[0-9a-fA-F]+' | head -1)

echo ""
echo "Deployed!"
echo "  Contract: $CONTRACT_ADDRESS"
echo "  Explorer: $EXPLORER/contract/$CONTRACT_ADDRESS"
echo ""
echo "Set in frontend/.env:"
echo "  REACT_APP_CONTRACT_ADDRESS=$CONTRACT_ADDRESS"
