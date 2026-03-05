# Veritas Frontend

A React frontend for the Veritas blind voting system on Starknet.

## Features

- 🦊 **Wallet Connection**: Connect to Starknet wallets (Argent X, Braavos)
- 🔐 **Blind Voting**: Commit-Reveal scheme for private voting
- 📊 **Real-time Results**: View voting results after reveal phase
- 📱 **Responsive Design**: Works on desktop and mobile
- ⚡ **Fast & Secure**: Built with modern React and Starknet.js

## Getting Started

### Prerequisites

- Node.js 16+ 
- npm or yarn
- Starknet wallet (Argent X, Braavos, etc.)

### Installation

```bash
# Clone the repository
git clone https://github.com/doomhammerhell/veritas
cd veritas/frontend

# Install dependencies
npm install

# Set environment variables
cp .env.example .env
# Edit .env with your contract address
```

### Configuration

Create a `.env` file in the frontend directory:

```env
REACT_APP_CONTRACT_ADDRESS=0x...  # Your deployed contract address
REACT_APP_NETWORK=testnet          # testnet or mainnet
REACT_APP_RPC_URL=https://starknet-testnet.public.blastapi.io
```

### Development

```bash
# Start development server
npm start

# Build for production
npm run build

# Run tests
npm test
```

The app will be available at `http://localhost:3000`.

## Usage

1. **Connect Wallet**: Connect your Starknet wallet
2. **Commit Vote**: Select your option and commit your vote
3. **Wait for Deadline**: Wait for voting period to end
4. **Reveal Vote**: Reveal your vote to be counted
5. **View Results**: See the final voting results

## Architecture

### Components

- **App.js**: Main application component
- **Wallet Connection**: Starknet wallet integration
- **Voting Interface**: Commit and reveal phases
- **Results Display**: Real-time voting results

### Security Features

- **Private Voting**: Votes are hidden during commit phase
- **Cryptographic Verification**: Pedersen hash commitments
- **Anti-Double Voting**: One vote per address
- **Time-based Phases**: Strict commit/reveal timing

## Contract Integration

The frontend integrates with the Veritas smart contract:

```javascript
// Contract ABI
const VERITAS_ABI = [
  // ... contract functions
];

// Contract interaction
const contract = new Contract(VERITAS_ABI, CONTRACT_ADDRESS, provider);
await contract.commit_vote(commitment);
await contract.reveal_vote(vote, salt);
```

## Deployment

### Netlify

1. Connect your repository to Netlify
2. Set environment variables in Netlify dashboard
3. Deploy automatically on push to main branch

### Vercel

1. Import your repository to Vercel
2. Configure environment variables
3. Deploy automatically

### Static Hosting

```bash
# Build static files
npm run build

# Deploy build folder to any static hosting service
```

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `REACT_APP_CONTRACT_ADDRESS` | Deployed contract address | Yes |
| `REACT_APP_NETWORK` | Network (testnet/mainnet) | Yes |
| `REACT_APP_RPC_URL` | Starknet RPC endpoint | Optional |

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## Troubleshooting

### Wallet Connection Issues

- Ensure you have a Starknet wallet installed
- Check if you're on the correct network (testnet/mainnet)
- Try refreshing the page and reconnecting

### Transaction Failures

- Check if you have enough ETH for gas fees
- Verify contract address is correct
- Ensure voting period is still open for commits

### MetaMask Issues

- MetaMask is not compatible with Starknet
- Use Argent X, Braavos, or other Starknet wallets

## Support

- 📖 [Documentation](../README.md)
- 🐛 [Issues](https://github.com/doomhammerhell/veritas/issues)
- 💬 [Discussions](https://github.com/doomhammerhell/veritas/discussions)

## License

MIT License - see [LICENSE](../LICENSE) file for details.
