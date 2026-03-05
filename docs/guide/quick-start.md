# Quick Start Guide

## Prerequisites

Before you begin, ensure you have the following installed:

- Node.js 20.x or higher
- Rust and Cairo 2.8.0 or higher
- A Starknet wallet (Argent X, Braavos, or MetaMask with Starknet)

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/veritas-org/veritas.git
cd veritas
```

### 2. Install Dependencies

```bash
npm install
npm run prepare
```

### 3. Setup Cairo Environment

```bash
# Install Cairo
curl --proto '=https' --tlsv1.2 -sSf https://sw.kairo.network/cairo/install.sh | sh
source ~/.bashrc

# Install project dependencies
scarb fetch
```

## Your First Voting Contract

### 1. Build the Contracts

```bash
# Build all contract versions
./scripts/build.sh

# Or build a specific version
./scripts/build.sh basic
```

### 2. Deploy to Testnet

```bash
# Deploy to Starknet testnet
./scripts/deploy_modular.sh testnet basic

# This will output your contract address
```

### 3. Interact with the Contract

```javascript
import { Account, Contract, json } from 'starknet';

// Connect to your account
const account = new Account(provider, address, privateKey);

// Load contract
const contract = new Contract(
  json.parse(contractAbi),
  contractAddress,
  account
);

// Commit a vote
await contract.commit_vote(commitment);

// Reveal a vote
await contract.reveal_vote(vote, salt);
```

## Basic Usage

### Creating a Voting Session

```cairo
// Initialize voting with 3 options, 24 hours duration
let voting = VeritasContract.new(
    admin_address,
    3,  // max_options
    86400  // voting_duration (24 hours)
);
```

### Committing a Vote

```cairo
// Generate commitment from vote and salt
let vote = 1;  // Vote for option 1
let salt = 12345;
let commitment = pedersen_hash(vote, salt);

// Commit the vote
contract.commit_vote(commitment);
```

### Revealing a Vote

```cairo
// Reveal the vote after voting period ends
contract.reveal_vote(vote, salt);
```

## Frontend Integration

### 1. Install Frontend Dependencies

```bash
cd frontend
npm install
```

### 2. Configure Environment

```bash
cp .env.example .env
# Edit .env with your configuration
```

### 3. Start the Development Server

```bash
npm start
```

### 4. Use the Veritas React Components

```jsx
import { VeritasProvider, VotingCard, ResultsDisplay } from '@veritas/react';

function App() {
  return (
    <VeritasProvider contractAddress="0x...">
      <VotingCard />
      <ResultsDisplay />
    </VeritasProvider>
  );
}
```

## Testing

### Run Cairo Tests

```bash
# Run all tests
scarb test

# Run specific test
scarb test test_voting_mechanism
```

### Run Frontend Tests

```bash
cd frontend
npm test
```

### Run Integration Tests

```bash
./scripts/test.sh integration basic
```

## Configuration

### Environment Variables

```bash
# .env
STARKNET_NETWORK=testnet
STARKNET_RPC_URL=https://starknet-testnet.public.blastapi.io
CONTRACT_ADDRESS=0x...
PRIVATE_KEY=your_private_key
```

### Contract Configuration

```toml
# Scarb.toml
[package]
name = "veritas"
version = "0.4.0"
edition = "2024_07"

[dependencies]
starknet = ">=2.8.0"
```

## Next Steps

1. **Explore Advanced Features**: Learn about quadratic voting, delegation, and ZK proofs
2. **Read the Architecture Guide**: Understand the system design
3. **Check Security Best Practices**: Ensure secure implementation
4. **Join the Community**: Get help and contribute

## Troubleshooting

### Common Issues

**Q: Build fails with "scarb not found"**
A: Ensure Cairo is properly installed and in your PATH

**Q: Contract deployment fails**
A: Check your account balance and network connection

**Q: Frontend won't connect to contract**
A: Verify contract address and network configuration

### Getting Help

- **Documentation**: [docs.veritas.io](https://docs.veritas.io)
- **Discord**: [Join our community](https://discord.gg/veritas)
- **GitHub Issues**: [Report bugs](https://github.com/veritas-org/veritas/issues)
- **Email**: support@veritas.io

## Resources

- [API Reference](/api/)
- [Security Guide](/security/)
- [Examples](/examples/)
- [Architecture](/guide/architecture)
- [Contributing](https://github.com/veritas-org/veritas/blob/main/CONTRIBUTING.md)
