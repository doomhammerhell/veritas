# Deploy to Testnet

## Prerequisites

1. Install [starkli](https://github.com/xJonathanLEI/starkli):
   ```bash
   curl https://get.starkli.sh | sh
   starkliup
   ```

2. Create a wallet and fund it with testnet ETH from the [Sepolia faucet](https://starknet-faucet.vercel.app/).

## Setup starkli account

```bash
# Create keystore (you'll set a password)
mkdir -p ~/.starkli-wallets/deployer
starkli signer keystore from-key ~/.starkli-wallets/deployer/keystore.json

# Create account descriptor
# Replace 0xYOUR_ADDRESS with your funded account address
starkli account fetch 0xYOUR_ADDRESS \
  --rpc https://starknet-sepolia.public.blastapi.io/rpc/v0_7 \
  --output ~/.starkli-wallets/deployer/account.json
```

## Set environment

```bash
export STARKNET_ACCOUNT=~/.starkli-wallets/deployer/account.json
export STARKNET_KEYSTORE=~/.starkli-wallets/deployer/keystore.json
```

## Build

```bash
scarb build
```

## Deploy

```bash
# Parameters: <network> <admin_address> <num_options> <commit_dur_secs> <reveal_dur_secs>
# Example: 5 options, 1 hour commit, 1 hour reveal
./scripts/deploy.sh testnet 0xYOUR_ADDRESS 5 3600 3600
```

The script will:
1. Declare the contract class on Sepolia
2. Deploy an instance with your parameters
3. Print the contract address and Starkscan link

## Configure frontend

```bash
cd frontend
cp .env.example .env
# Edit .env:
#   REACT_APP_CONTRACT_ADDRESS=0x<address from deploy output>
#   REACT_APP_STARKNET_NETWORK=sepolia
npm install --legacy-peer-deps
npm start
```

## Verify

Open the Starkscan link from the deploy output. You should see:
- The contract class with all functions listed
- Constructor parameters matching what you passed
- No pending transactions

Call a view function to verify:
```bash
starkli call 0xCONTRACT_ADDRESS get_phase \
  --rpc https://starknet-sepolia.public.blastapi.io/rpc/v0_7
```

Should return `0` (commit phase).
