# Veritas Deployment Guide

## Overview

This comprehensive guide covers the deployment of the Veritas voting system on both testnet and mainnet StarkNet networks. It includes prerequisites, step-by-step instructions, and troubleshooting tips.

## Prerequisites

### Required Tools

- **Node.js** >= 16.0.0
- **Starkli** - StarkNet CLI tool
- **Cairo 1.0** compiler
- **Scarb** - Cairo package manager
- **Git** - Version control

### Environment Setup

```bash
# Install Starkli
curl -L https://raw.githubusercontent.com/xJonathanLEI/starkli/main/install.sh | bash

# Install Scarb
curl --proto '=https' --tlsv1.2 -sSf https://sw.kkrt.sh/install.sh | sh

# Verify installations
starkli --version
scarb --version
```

## Network Configuration

### Testnet Configuration

```bash
# Set testnet environment
export STARKNET_NETWORK=testnet
export STARKNET_RPC=https://starknet-testnet.infura.io/v3/YOUR_INFURA_KEY

# Account setup
starkli account import --name testnet_account --network testnet
```

### Mainnet Configuration

```bash
# Set mainnet environment
export STARKNET_NETWORK=mainnet
export STARKNET_RPC=https://starknet-mainnet.infura.io/v3/YOUR_INFURA_KEY

# Account setup
starkli account import --name mainnet_account --network mainnet
```

## Contract Compilation

### Build Process

```bash
# Clone repository
git clone https://github.com/your-org/veritas.git
cd veritas

# Install dependencies
npm install

# Build contract
npm run build:cairo

# Build for production
npm run build:cairo:release
```

### Build Verification

```bash
# Verify compilation
scarb build

# Check compiled artifacts
ls -la target/dev/
```

## Testnet Deployment

### Step 1: Account Preparation

```bash
# Check account balance
starkli account balance --account testnet_account

# Fund account if needed (use testnet faucet)
# Visit: https://faucet.starknet.io/
```

### Step 2: Contract Deployment

```bash
# Deploy main contract
starkli declare --account testnet_account --network testnet target/dev/veritas.json

# Get class hash
CLASS_HASH=$(starkli class-hash target/dev/veritas.json)

# Deploy contract instance
starkli deploy --account testnet_account --network testnet \
  --class-hash $CLASS_HASH \
  --constructor-args 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
```

### Step 3: Verification

```bash
# Verify deployment
CONTRACT_ADDRESS="0x..." # From deployment output
starkli call --account testnet_account --network testnet \
  --address $CONTRACT_ADDRESS \
  --function get_voting_status

# Check contract state
starkli get-storage-at --address $CONTRACT_ADDRESS --key 0 --network testnet
```

### Step 4: Testing

```bash
# Run test suite
npm run test

# Run integration tests
npm run test:integration

# Manual testing
starkli invoke --account testnet_account --network testnet \
  --address $CONTRACT_ADDRESS \
  --function start_voting \
  --args 3600 # 1 hour voting period

# Test voting
COMMITMENT=$(starkli hash pedersen --inputs 1 12345)
starkli invoke --account testnet_account --network testnet \
  --address $CONTRACT_ADDRESS \
  --function commit_vote \
  --args $COMMITMENT

# Reveal vote
starkli invoke --account testnet_account --network testnet \
  --address $CONTRACT_ADDRESS \
  --function reveal_vote \
  --args 1 12345

# Check results
starkli call --account testnet_account --network testnet \
  --address $CONTRACT_ADDRESS \
  --function get_results
```

## Mainnet Deployment

### Step 1: Security Preparation

```bash
# Security checklist
npm run security:check

# Audit verification
npm run audit:verify

# Final build verification
npm run build:cairo:release
```

### Step 2: Account Setup

```bash
# Check mainnet account
starkli account balance --account mainnet_account

# Ensure sufficient funds (minimum 0.1 ETH for deployment)
```

### Step 3: Contract Declaration

```bash
# Declare contract on mainnet
starkli declare --account mainnet_account --network mainnet target/release/veritas.json

# Save class hash
MAINNET_CLASS_HASH=$(starkli class-hash target/release/veritas.json)
echo "Mainnet Class Hash: $MAINNET_CLASS_HASH"
```

### Step 4: Contract Deployment

```bash
# Deploy main contract
ADMIN_ADDRESS="0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"

starkli deploy --account mainnet_account --network mainnet \
  --class-hash $MAINNET_CLASS_HASH \
  --constructor-args $ADMIN_ADDRESS

# Save contract address
MAINNET_CONTRACT_ADDRESS="0x..." # From deployment output
echo "Mainnet Contract Address: $MAINNET_CONTRACT_ADDRESS"
```

### Step 5: Post-Deployment Verification

```bash
# Verify contract functionality
starkli call --account mainnet_account --network mainnet \
  --address $MAINNET_CONTRACT_ADDRESS \
  --function get_voting_status

# Check admin access
starkli call --account mainnet_account --network mainnet \
  --address $MAINNET_CONTRACT_ADDRESS \
  --function get_admin

# Test basic functionality
starkli invoke --account mainnet_account --network mainnet \
  --address $MAINNET_CONTRACT_ADDRESS \
  --function start_voting \
  --args 86400 # 24 hours
```

## Advanced Module Deployment

### AI Module Deployment

```bash
# Deploy AI module
starkli declare --account mainnet_account --network mainnet target/release/ai.json

AI_CLASS_HASH=$(starkli class-hash target/release/ai.json)

starkli deploy --account mainnet_account --network mainnet \
  --class-hash $AI_CLASS_HASH \
  --constructor-args $ADMIN_ADDRESS
```

### Analytics Module Deployment

```bash
# Deploy analytics module
starkli declare --account mainnet_account --network mainnet target/release/analytics.json

ANALYTICS_CLASS_HASH=$(starkli class-hash target/release/analytics.json)

starkli deploy --account mainnet_account --network mainnet \
  --class-hash $ANALYTICS_CLASS_HASH \
  --constructor-args $ADMIN_ADDRESS
```

### Quantum Module Deployment

```bash
# Deploy quantum module
starkli declare --account mainnet_account --network mainnet target/release/quantum.json

QUANTUM_CLASS_HASH=$(starkli class-hash target/release/quantum.json)

starkli deploy --account mainnet_account --network mainnet \
  --class-hash $QUANTUM_CLASS_HASH \
  --constructor-args $ADMIN_ADDRESS
```

### Interoperability Module Deployment

```bash
# Deploy interoperability module
starkli declare --account mainnet_account --network mainnet target/release/interoperability.json

INTEROP_CLASS_HASH=$(starkli class-hash target/release/interoperability.json)

starkli deploy --account mainnet_account --network mainnet \
  --class-hash $INTEROP_CLASS_HASH \
  --constructor-args $ADMIN_ADDRESS
```

## Configuration Management

### Environment Variables

```bash
# Create .env file
cat > .env << EOF
# Network Configuration
STARKNET_NETWORK=mainnet
STARKNET_RPC=https://starknet-mainnet.infura.io/v3/YOUR_INFURA_KEY

# Account Configuration
ACCOUNT_NAME=mainnet_account
ACCOUNT_ADDRESS=0x...

# Contract Addresses
MAIN_CONTRACT=0x...
AI_MODULE_CONTRACT=0x...
ANALYTICS_MODULE_CONTRACT=0x...
QUANTUM_MODULE_CONTRACT=0x...
INTEROP_MODULE_CONTRACT=0x...

# Security
ADMIN_ADDRESS=0x...
PRIVATE_KEY=your_private_key_here
EOF

# Load environment
source .env
```

### Deployment Scripts

```bash
#!/bin/bash
# deploy.sh - Main deployment script

set -e

NETWORK=${1:-testnet}
ACCOUNT=${2:-${NETWORK}_account}

echo "Deploying to $NETWORK..."

# Build contract
npm run build:cairo:release

# Declare contract
echo "Declaring contract..."
CLASS_HASH=$(starkli declare --account $ACCOUNT --network $NETWORK target/release/veritas.json | grep "Class hash" | awk '{print $3}')

# Deploy contract
echo "Deploying contract..."
ADMIN_ADDRESS="0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
CONTRACT_ADDRESS=$(starkli deploy --account $ACCOUNT --network $NETWORK --class-hash $CLASS_HASH --constructor-args $ADMIN_ADDRESS | grep "Contract address" | awk '{print $3}')

echo "Deployment complete!"
echo "Class Hash: $CLASS_HASH"
echo "Contract Address: $CONTRACT_ADDRESS"

# Save to config
echo "CONTRACT_ADDRESS=$CONTRACT_ADDRESS" > .env.$NETWORK
echo "CLASS_HASH=$CLASS_HASH" >> .env.$NETWORK
```

## Monitoring and Maintenance

### Health Checks

```bash
#!/bin/bash
# health-check.sh - Contract health monitoring

CONTRACT_ADDRESS=${1:-$MAINNET_CONTRACT_ADDRESS}
NETWORK=${2:-mainnet}

echo "Checking contract health..."

# Check contract is responsive
RESPONSE=$(starkli call --network $NETWORK --address $CONTRACT_ADDRESS --function get_voting_status)
echo "Voting Status: $RESPONSE"

# Check admin access
ADMIN=$(starkli call --network $NETWORK --address $CONTRACT_ADDRESS --function get_admin)
echo "Admin Address: $ADMIN"

# Check contract balance
BALANCE=$(starkli account balance --address $CONTRACT_ADDRESS --network $NETWORK)
echo "Contract Balance: $BALANCE"

echo "Health check complete!"
```

### Log Monitoring

```bash
#!/bin/bash
# monitor.sh - Event monitoring

CONTRACT_ADDRESS=${1:-$MAINNET_CONTRACT_ADDRESS}
NETWORK=${2:-mainnet}

echo "Monitoring contract events..."

# Monitor new events
starkli get-events --network $NETWORK --address $CONTRACT_ADDRESS --from-block latest --to-block latest

# Monitor specific events
starkli get-events --network $NETWORK --address $CONTRACT_ADDRESS \
  --keys "0x..." --from-block latest --to-block latest
```

## Troubleshooting

### Common Issues

#### 1. Compilation Errors

```bash
# Error: "Method read not found"
# Solution: Import storage traits
echo "Adding storage trait imports..."

# Error: "Type annotations needed"
# Solution: Add explicit type annotations
echo "Adding explicit type annotations..."

# Error: "Ambiguous method call"
# Solution: Use explicit trait calls
echo "Using explicit trait calls..."
```

#### 2. Deployment Failures

```bash
# Error: "Insufficient balance"
# Solution: Fund account
echo "Funding account..."

# Error: "Invalid class hash"
# Solution: Verify class hash
echo "Verifying class hash..."

# Error: "Constructor failed"
# Solution: Check constructor arguments
echo "Checking constructor arguments..."
```

#### 3. Runtime Errors

```bash
# Error: "Admin access required"
# Solution: Use admin account
echo "Using admin account..."

# Error: "Voting not active"
# Solution: Start voting session
echo "Starting voting session..."

# Error: "Invalid commitment"
# Solution: Check commitment calculation
echo "Checking commitment calculation..."
```

### Debug Tools

```bash
# Debug contract state
starkli get-storage-at --address $CONTRACT_ADDRESS --key 0 --network $NETWORK

# Debug transaction
starkli get-transaction-receipt --transaction-hash 0x... --network $NETWORK

# Debug block
starkli get-block --block-number latest --network $NETWORK
```

## Security Best Practices

### 1. Key Management

```bash
# Use hardware wallets for mainnet
# Store private keys securely
# Use multi-sig for critical operations
```

### 2. Access Control

```bash
# Implement principle of least privilege
# Regular access audits
# Time-limited access tokens
```

### 3. Monitoring

```bash
# Real-time monitoring
# Alert systems
# Automated health checks
```

### 4. Backup and Recovery

```bash
# Regular backups
# Disaster recovery plan
# Redundant deployments
```

## Performance Optimization

### Gas Optimization

```bash
# Use batch operations
# Optimize storage layout
# Minimize external calls
```

### Network Optimization

```bash
# Use appropriate RPC endpoints
# Implement caching
# Optimize transaction batching
```

## Upgrade Process

### 1. Preparation

```bash
# Backup current state
# Prepare new contract
# Test upgrade on testnet
```

### 2. Execution

```bash
# Deploy new contract
# Migrate state if needed
# Update references
```

### 3. Verification

```bash
# Test new functionality
# Verify state integrity
# Monitor performance
```

## Support and Resources

### Documentation

- [API Reference](./api.md)
- [Security Audit](./audit.md)
- [Architecture Overview](./architecture.md)

### Community

- **Discord**: [Veritas Community](https://discord.gg/veritas)
- **Twitter**: [@VeritasVoting](https://twitter.com/VeritasVoting)
- **GitHub**: [Issues](https://github.com/your-org/veritas/issues)

### Professional Support

- **Technical Support**: tech@veritas.io
- **Security Team**: security@veritas.io
- **Deployment Support**: deploy@veritas.io

## Conclusion

This deployment guide provides comprehensive instructions for deploying the Veritas voting system on both testnet and mainnet. Following these guidelines ensures a secure, efficient, and successful deployment.

For additional support or questions, please refer to the documentation or contact the support team.

---

**Last Updated**: March 4, 2026  
**Version**: v0.4.0
