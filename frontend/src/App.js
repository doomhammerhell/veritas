import React, { useState, useEffect, useCallback } from 'react';
import { connect, disconnect } from 'get-starknet';
import { Contract, RpcProvider, hash } from 'starknet';
import { VERITAS_ABI } from './abi';
import './App.css';

const CONTRACT_ADDRESS = process.env.REACT_APP_CONTRACT_ADDRESS || '';
const NETWORK = process.env.REACT_APP_STARKNET_NETWORK || 'sepolia';

const RPC_URLS = {
  sepolia: 'https://starknet-sepolia.public.blastapi.io/rpc/v0_7',
  mainnet: 'https://starknet-mainnet.public.blastapi.io/rpc/v0_7',
};

const PHASE_LABELS = ['Commit Phase', 'Reveal Phase', 'Voting Ended', 'Paused'];
const PHASE_COLORS = ['#22c55e', '#3b82f6', '#6b7280', '#ef4444'];

function computePedersenCommitment(vote, salt) {
  return hash.computePedersenHash(vote.toString(), salt);
}

function generateSalt() {
  const arr = new Uint8Array(31); // felt252 < 2^251
  crypto.getRandomValues(arr);
  return '0x' + Array.from(arr, (b) => b.toString(16).padStart(2, '0')).join('');
}

function App() {
  const [wallet, setWallet] = useState(null);
  const [account, setAccount] = useState(null);
  const [provider] = useState(new RpcProvider({ nodeUrl: RPC_URLS[NETWORK] }));

  const [phase, setPhase] = useState(0);
  const [numOptions, setNumOptions] = useState(2);
  const [commitEnd, setCommitEnd] = useState(0);
  const [revealEnd, setRevealEnd] = useState(0);
  const [totalCommits, setTotalCommits] = useState(0);
  const [totalReveals, setTotalReveals] = useState(0);
  const [paused, setPaused] = useState(false);
  const [tallies, setTallies] = useState([]);

  const [selectedVote, setSelectedVote] = useState(0);
  const [votingState, setVotingState] = useState('idle'); // idle | committed | revealed
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [txHash, setTxHash] = useState('');

  const getReadContract = useCallback(() => {
    if (!CONTRACT_ADDRESS) return null;
    return new Contract(VERITAS_ABI, CONTRACT_ADDRESS, provider);
  }, [provider]);

  const getWriteContract = useCallback(() => {
    if (!CONTRACT_ADDRESS || !account) return null;
    return new Contract(VERITAS_ABI, CONTRACT_ADDRESS, account);
  }, [account]);

  // Load contract state
  const loadState = useCallback(async () => {
    const c = getReadContract();
    if (!c) return;
    try {
      const [p, n, ce, re, tc, tr, pa] = await Promise.all([
        c.get_phase(),
        c.get_num_options(),
        c.get_commit_end(),
        c.get_reveal_end(),
        c.get_total_commits(),
        c.get_total_reveals(),
        c.is_paused(),
      ]);
      setPhase(Number(p));
      setNumOptions(Number(n));
      setCommitEnd(Number(ce));
      setRevealEnd(Number(re));
      setTotalCommits(Number(tc));
      setTotalReveals(Number(tr));
      setPaused(Boolean(pa));

      // Load tallies
      const opts = Number(n);
      const tallyPromises = [];
      for (let i = 0; i < opts; i++) {
        tallyPromises.push(c.get_tally(i));
      }
      const results = await Promise.all(tallyPromises);
      setTallies(results.map(Number));
    } catch (e) {
      console.error('Failed to load state:', e);
    }
  }, [getReadContract]);

  useEffect(() => {
    loadState();
    const interval = setInterval(loadState, 15000);
    return () => clearInterval(interval);
  }, [loadState]);

  // Check if user already committed (from localStorage)
  useEffect(() => {
    const saved = localStorage.getItem('veritas_salt');
    if (saved) setVotingState('committed');
  }, []);

  const handleConnect = async () => {
    try {
      const starknet = await connect();
      if (!starknet) return;
      await starknet.enable();
      setWallet(starknet);
      setAccount(starknet.account);
    } catch (e) {
      setError('Wallet connection failed');
    }
  };

  const handleDisconnect = async () => {
    await disconnect();
    setWallet(null);
    setAccount(null);
  };

  const handleCommit = async () => {
    const c = getWriteContract();
    if (!c) return setError('Connect wallet first');
    setLoading(true);
    setError('');
    setTxHash('');
    try {
      const salt = generateSalt();
      const commitment = computePedersenCommitment(selectedVote, salt);

      const tx = await c.commit_vote(commitment);
      setTxHash(tx.transaction_hash);
      await provider.waitForTransaction(tx.transaction_hash);

      localStorage.setItem('veritas_salt', salt);
      localStorage.setItem('veritas_vote', selectedVote.toString());
      setVotingState('committed');
      await loadState();
    } catch (e) {
      setError(e.message || 'Commit failed');
    } finally {
      setLoading(false);
    }
  };

  const handleReveal = async () => {
    const c = getWriteContract();
    if (!c) return setError('Connect wallet first');
    setLoading(true);
    setError('');
    setTxHash('');
    try {
      const salt = localStorage.getItem('veritas_salt');
      const vote = parseInt(localStorage.getItem('veritas_vote'), 10);
      if (!salt || isNaN(vote)) throw new Error('No committed vote found locally');

      const tx = await c.reveal_vote(vote, salt);
      setTxHash(tx.transaction_hash);
      await provider.waitForTransaction(tx.transaction_hash);

      localStorage.removeItem('veritas_salt');
      localStorage.removeItem('veritas_vote');
      setVotingState('revealed');
      await loadState();
    } catch (e) {
      setError(e.message || 'Reveal failed');
    } finally {
      setLoading(false);
    }
  };

  const fmtTime = (ts) => (ts ? new Date(ts * 1000).toLocaleString() : '--');
  const explorerBase =
    NETWORK === 'mainnet' ? 'https://starkscan.co' : 'https://sepolia.starkscan.co';

  return (
    <div className="App">
      <header className="App-header">
        <h1>Veritas</h1>
        <p>Commit-reveal blind voting on StarkNet</p>
        {!account ? (
          <button onClick={handleConnect} className="connect-btn">
            Connect Wallet
          </button>
        ) : (
          <div className="wallet-info">
            <span>
              {account.address.slice(0, 6)}...{account.address.slice(-4)}
            </span>
            <button onClick={handleDisconnect} className="disconnect-btn">
              Disconnect
            </button>
          </div>
        )}
      </header>

      <main className="App-main">
        {!CONTRACT_ADDRESS && (
          <div className="error-message">
            Set REACT_APP_CONTRACT_ADDRESS in .env to connect to a deployed contract.
          </div>
        )}

        {error && <div className="error-message">{error}</div>}
        {txHash && (
          <div className="tx-link">
            TX:{' '}
            <a href={`${explorerBase}/tx/${txHash}`} target="_blank" rel="noreferrer">
              {txHash.slice(0, 10)}...
            </a>
          </div>
        )}

        <section className="info-grid">
          <div className="info-card">
            <h3>Phase</h3>
            <p style={{ color: PHASE_COLORS[phase] }}>{PHASE_LABELS[phase]}</p>
          </div>
          <div className="info-card">
            <h3>Options</h3>
            <p>{numOptions}</p>
          </div>
          <div className="info-card">
            <h3>Commits</h3>
            <p>{totalCommits}</p>
          </div>
          <div className="info-card">
            <h3>Reveals</h3>
            <p>{totalReveals}</p>
          </div>
          <div className="info-card">
            <h3>Commit Deadline</h3>
            <p>{fmtTime(commitEnd)}</p>
          </div>
          <div className="info-card">
            <h3>Reveal Deadline</h3>
            <p>{fmtTime(revealEnd)}</p>
          </div>
        </section>

        {/* Commit */}
        {phase === 0 && votingState === 'idle' && account && (
          <section className="voting-section">
            <h2>Cast Your Vote</h2>
            <p>Select an option and commit. Your choice stays secret until the reveal phase.</p>
            <div className="vote-options">
              {Array.from({ length: numOptions }, (_, i) => (
                <label key={i} className="vote-option">
                  <input
                    type="radio"
                    name="vote"
                    value={i}
                    checked={selectedVote === i}
                    onChange={() => setSelectedVote(i)}
                  />
                  <span>Option {i}</span>
                </label>
              ))}
            </div>
            <button onClick={handleCommit} disabled={loading} className="vote-button">
              {loading ? 'Committing...' : 'Commit Vote'}
            </button>
          </section>
        )}

        {/* Committed — waiting for reveal phase */}
        {votingState === 'committed' && (
          <section className="voting-section">
            <h2>Vote Committed</h2>
            <p>Your commitment is on-chain. Return during the reveal phase to finalize.</p>
            {phase === 1 && account && (
              <button onClick={handleReveal} disabled={loading} className="vote-button">
                {loading ? 'Revealing...' : 'Reveal Vote'}
              </button>
            )}
          </section>
        )}

        {/* Revealed */}
        {votingState === 'revealed' && (
          <section className="voting-section">
            <h2>Vote Revealed</h2>
            <p>Your vote has been counted.</p>
          </section>
        )}

        {/* Results */}
        {tallies.length > 0 && (
          <section className="results-section">
            <h2>Results</h2>
            <div className="results-grid">
              {tallies.map((count, i) => (
                <div key={i} className="result-row">
                  <span>Option {i}</span>
                  <span className="result-count">{count} votes</span>
                </div>
              ))}
            </div>
          </section>
        )}
      </main>

      <footer className="App-footer">
        {CONTRACT_ADDRESS && (
          <a href={`${explorerBase}/contract/${CONTRACT_ADDRESS}`} target="_blank" rel="noreferrer">
            Contract on Starkscan
          </a>
        )}
      </footer>
    </div>
  );
}

export default App;
