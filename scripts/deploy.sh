#!/bin/bash

# Deployment script for Veritas contract
# Usage: ./deploy.sh [network] [private_key]

set -e

NETWORK=${1:-testnet}
PRIVATE_KEY=${2:-$TESTNET_PRIVATE_KEY}

echo "🚀 Deploying Veritas contract to $NETWORK..."

# Build the contract
echo "📦 Building contract..."
npm run build:cairo

# Deploy based on network
if [ "$NETWORK" = "testnet" ]; then
    echo "🔗 Deploying to StarkNet Testnet..."
    starkli declare --account testnet_account --rpc testnet --contract target/dev/veritas_Veritas.sierra.json
    starkli deploy --account testnet_account --rpc testnet --class-hash <CLASS_HASH> --constructor 0x1234
elif [ "$NETWORK" = "mainnet" ]; then
    echo "🔗 Deploying to StarkNet Mainnet..."
    starkli declare --account mainnet_account --rpc mainnet --contract target/dev/veritas_Veritas.sierra.json
    starkli deploy --account mainnet_account --rpc mainnet --class-hash <CLASS_HASH> --constructor 0x1234
else
    echo "❌ Invalid network. Use 'testnet' or 'mainnet'"
    exit 1
fi

echo "✅ Deployment completed!"
echo "📋 Contract address: <CONTRACT_ADDRESS>"
echo "🔗 Explorer: https://$NETWORK.starkscan.io/contract/<CONTRACT_ADDRESS>"
