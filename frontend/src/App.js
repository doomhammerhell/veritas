import React, { useState, useEffect } from 'react';
import { useAccount, useConnectors } from '@starknet-react/core';
import './App.css';

// Veritas Contract ABI (simplified)
const VERITAS_ABI = [
  {
    "type": "function",
    "name": "commit_vote",
    "inputs": [{"name": "commitment", "type": "felt"}],
    "outputs": [],
    "stateMutability": "external"
  },
  {
    "type": "function", 
    "name": "reveal_vote",
    "inputs": [
      {"name": "vote", "type": "u8"},
      {"name": "salt", "type": "felt"}
    ],
    "outputs": [],
    "stateMutability": "external"
  },
  {
    "type": "function",
    "name": "get_tally",
    "inputs": [{"name": "option", "type": "u8"}],
    "outputs": [{"name": "tally", "type": "u128"}],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "has_voted",
    "inputs": [{"name": "address", "type": "ContractAddress"}],
    "outputs": [{"name": "voted", "type": "bool"}],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "is_voting_closed",
    "inputs": [],
    "outputs": [{"name": "closed", "type": "bool"}],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "get_total_voters",
    "inputs": [],
    "outputs": [{"name": "total", "type": "u128"}],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "get_max_options",
    "inputs": [],
    "outputs": [{"name": "max", "type": "u8"}],
    "stateMutability": "view"
  }
];

// Contract configuration
const CONTRACT_ADDRESS = process.env.REACT_APP_CONTRACT_ADDRESS || "0x..."; // Replace with deployed contract

function App() {
  const { address, isConnected } = useAccount();
  const { connect, connectors } = useConnectors();
  const [votingState, setVotingState] = useState('idle');
  const [selectedVote, setSelectedVote] = useState(1);
  const [results, setResults] = useState([]);
  const [votingInfo, setVotingInfo] = useState({
    totalVoters: 0,
    maxOptions: 5,
    isClosed: false,
    hasVoted: false
  });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  // Generate Pedersen hash (simplified - in production use proper Starknet library)
  const generateCommitment = (vote, salt) => {
    // This is a simplified hash function for demo
    // In production, use actual Pedersen hash from Starknet library
    const hashInput = `${vote}${salt}`;
    let hash = 0;
    for (let i = 0; i < hashInput.length; i++) {
      hash = ((hash << 5) - hash) + hashInput.charCodeAt(i);
      hash = hash & hash; // Convert to 32-bit integer
    }
    return hash.toString();
  };

  // Generate secure salt
  const generateSecureSalt = () => {
    const array = new Uint8Array(32);
    crypto.getRandomValues(array);
    return Array.from(array, byte => byte.toString(16).padStart(2, '0')).join('');
  };

  // Load voting information
  const loadVotingInfo = async () => {
    if (!isConnected || !address) return;
    
    try {
      // Simulate contract calls (in production, use actual Starknet provider)
      const mockVotingInfo = {
        totalVoters: 25,
        maxOptions: 5,
        isClosed: false,
        hasVoted: false
      };
      setVotingInfo(mockVotingInfo);
    } catch (err) {
      console.error('Error loading voting info:', err);
      setError('Failed to load voting information');
    }
  };

  // Commit vote
  const handleCommitVote = async () => {
    if (!isConnected) {
      setError('Please connect your wallet first');
      return;
    }

    try {
      setLoading(true);
      setError('');
      setVotingState('committing');
      
      const salt = generateSecureSalt();
      const commitment = generateCommitment(selectedVote, salt);
      
      // Store salt locally for reveal phase
      localStorage.setItem('veritas_salt', salt);
      localStorage.setItem('veritas_vote', selectedVote.toString());
      localStorage.setItem('veritas_commitment', commitment);
      
      // Simulate contract call (in production, use actual Starknet contract)
      await new Promise(resolve => setTimeout(resolve, 2000)); // Simulate transaction
      
      setVotingState('committed');
      await loadVotingInfo();
    } catch (err) {
      console.error('Commit failed:', err);
      setError('Failed to commit vote. Please try again.');
      setVotingState('idle');
    } finally {
      setLoading(false);
    }
  };

  // Reveal vote
  const handleRevealVote = async () => {
    if (!isConnected) {
      setError('Please connect your wallet first');
      return;
    }

    try {
      setLoading(true);
      setError('');
      setVotingState('revealing');
      
      const salt = localStorage.getItem('veritas_salt');
      const vote = parseInt(localStorage.getItem('veritas_vote'));
      
      if (!salt || !vote) {
        throw new Error('No committed vote found');
      }
      
      // Simulate contract call (in production, use actual Starknet contract)
      await new Promise(resolve => setTimeout(resolve, 2000)); // Simulate transaction
      
      // Clear local storage
      localStorage.removeItem('veritas_salt');
      localStorage.removeItem('veritas_vote');
      localStorage.removeItem('veritas_commitment');
      
      setVotingState('revealed');
      await loadVotingInfo();
      await loadResults();
    } catch (err) {
      console.error('Reveal failed:', err);
      setError('Failed to reveal vote. Please try again.');
      setVotingState('committed');
    } finally {
      setLoading(false);
    }
  };

  // Load voting results
  const loadResults = async () => {
    try {
      // Simulate results (in production, use actual contract calls)
      const mockResults = [
        { option: 1, votes: 8, percentage: 32 },
        { option: 2, votes: 12, percentage: 48 },
        { option: 3, votes: 3, percentage: 12 },
        { option: 4, votes: 2, percentage: 8 },
        { option: 5, votes: 0, percentage: 0 }
      ];
      setResults(mockResults);
    } catch (err) {
      console.error('Error loading results:', err);
      setError('Failed to load results');
    }
  };

  // Format time remaining
  const formatTimeRemaining = () => {
    // Simulate deadline (in production, get from contract)
    const deadline = new Date();
    deadline.setHours(deadline.getHours() + 24); // 24 hours from now
    
    const now = new Date();
    const remaining = deadline - now;
    
    if (remaining <= 0) return 'Voting ended';
    
    const hours = Math.floor(remaining / (1000 * 60 * 60));
    const minutes = Math.floor((remaining % (1000 * 60 * 60)) / (1000 * 60));
    
    return `${hours}h ${minutes}m remaining`;
  };

  useEffect(() => {
    if (isConnected) {
      loadVotingInfo();
      loadResults();
    }
  }, [isConnected, address]);

  return (
    <div className="App">
      <header className="App-header">
        <h1>🛡️ Veritas</h1>
        <p>ZK-Powered Blind Voting for Communities</p>
      </header>

      <main className="App-main">
        {/* Wallet Connection */}
        <section className="wallet-section">
          {!isConnected ? (
            <div className="connect-wallet">
              <h2>Connect Your Wallet</h2>
              <p>Connect your Starknet wallet to participate in voting</p>
              <div className="connectors">
                {connectors.map((connector) => (
                  <button
                    key={connector.id}
                    onClick={() => connect(connector)}
                    className="connect-button"
                  >
                    Connect {connector.name}
                  </button>
                ))}
              </div>
            </div>
          ) : (
            <div className="wallet-connected">
              <p>✅ Connected: {address?.slice(0, 6)}...{address?.slice(-4)}</p>
            </div>
          )}
        </section>

        {/* Error Display */}
        {error && (
          <section className="error-section">
            <div className="error-message">
              ❌ {error}
            </div>
          </section>
        )}

        {/* Voting Information */}
        {isConnected && (
          <section className="voting-info">
            <div className="info-grid">
              <div className="info-card">
                <h3>Total Voters</h3>
                <p className="info-value">{votingInfo.totalVoters}</p>
              </div>
              <div className="info-card">
                <h3>Voting Options</h3>
                <p className="info-value">{votingInfo.maxOptions}</p>
              </div>
              <div className="info-card">
                <h3>Status</h3>
                <p className="info-value">
                  {votingInfo.isClosed ? '🔴 Closed' : '🟢 Open'}
                </p>
              </div>
              <div className="info-card">
                <h3>Time Remaining</h3>
                <p className="info-value">{formatTimeRemaining()}</p>
              </div>
            </div>
          </section>
        )}

        {/* Voting Interface */}
        {isConnected && !votingInfo.isClosed && (
          <section className="voting-section">
            <h2>Cast Your Vote</h2>
            
            {votingState === 'idle' && (
              <div className="commit-phase">
                <h3>Commit Phase</h3>
                <p>Select your option and commit your vote. Your choice will remain secret until the reveal phase.</p>
                
                <div className="vote-options">
                  {Array.from({ length: votingInfo.maxOptions }, (_, i) => i + 1).map((option) => (
                    <label key={option} className="vote-option">
                      <input
                        type="radio"
                        name="vote"
                        value={option}
                        checked={selectedVote === option}
                        onChange={(e) => setSelectedVote(parseInt(e.target.value))}
                      />
                      <span className="option-label">Option {option}</span>
                    </label>
                  ))}
                </div>
                
                <button
                  onClick={handleCommitVote}
                  disabled={loading}
                  className="vote-button commit-button"
                >
                  {loading ? 'Processing...' : 'Commit Vote'}
                </button>
              </div>
            )}

            {votingState === 'committed' && (
              <div className="committed-phase">
                <h3>✅ Vote Committed!</h3>
                <p>Your vote has been securely committed to the blockchain.</p>
                <p>Wait for the voting period to end, then return to reveal your vote.</p>
                <button
                  onClick={handleRevealVote}
                  disabled={loading || !votingInfo.isClosed}
                  className="vote-button reveal-button"
                >
                  {loading ? 'Processing...' : votingInfo.isClosed ? 'Reveal Vote' : 'Wait for Voting to End'}
                </button>
              </div>
            )}

            {votingState === 'revealed' && (
              <div className="revealed-phase">
                <h3>✅ Vote Revealed!</h3>
                <p>Thank you for participating! Your vote has been counted.</p>
              </div>
            )}
          </section>
        )}

        {/* Results Display */}
        {isConnected && (votingInfo.isClosed || votingState === 'revealed') && (
          <section className="results-section">
            <h2>Voting Results</h2>
            <div className="results-grid">
              {results.map((result) => (
                <div key={result.option} className="result-card">
                  <h4>Option {result.option}</h4>
                  <div className="vote-count">{result.votes} votes</div>
                  <div className="vote-percentage">{result.percentage}%</div>
                  <div className="vote-bar">
                    <div 
                      className="vote-fill" 
                      style={{ width: `${result.percentage}%` }}
                    ></div>
                  </div>
                </div>
              ))}
            </div>
          </section>
        )}
      </main>

      <footer className="App-footer">
        <p>Built with ❤️ for decentralized communities</p>
        <p>
          <a href="https://github.com/doomhammerhell/veritas" target="_blank" rel="noopener noreferrer">
            GitHub Repository
          </a>
        </p>
      </footer>
    </div>
  );
}

export default App;
