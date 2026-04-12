# Quick Start

## Prerequisites

- [Scarb](https://docs.swmansion.com/scarb/) 2.16+
- [Starknet Foundry](https://github.com/foundry-rs/starknet-foundry) 0.57+
- [starkli](https://github.com/xJonathanLEI/starkli) (for deployment)
- Node.js 20+ (for frontend)

## Build

```bash
scarb build
```

## Test

```bash
snforge test
```

## Deploy

```bash
./scripts/deploy.sh testnet 0xYOUR_ADMIN_ADDRESS 5 3600 3600
```

Parameters: `<network> <admin> <num_options> <commit_duration_secs> <reveal_duration_secs>`

## Run Frontend

```bash
cd frontend
cp .env.example .env
# Edit .env with your contract address
npm install
npm start
```

## Voting Flow

1. **Commit phase** — Connect wallet, select option, click "Commit Vote". The app computes `pedersen(vote, salt)` and submits it on-chain. Salt is saved in your browser.

2. **Reveal phase** — After the commit deadline, return and click "Reveal Vote". The app submits your `(vote, salt)` pair. The contract verifies the hash and counts your vote.

3. **Results** — After the reveal deadline, results are final and visible to everyone.
