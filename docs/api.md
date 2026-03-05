# Veritas API Reference

## Overview

This document provides a comprehensive API reference for the Veritas voting system, including all interfaces, functions, and data structures.

## Core Interfaces

### IVeritas - Main Voting Interface

```cairo
#[starknet::interface]
pub trait IVeritas<T> {
    // Core voting functions
    fn commit_vote(ref self: T, commitment: felt252);
    fn reveal_vote(ref self: T, vote: u32, salt: felt252);
    fn get_results(self: @T) -> Array<u32>;
    fn get_voting_status(self: @T) -> bool;
    
    // Admin functions
    fn start_voting(ref self: T, duration: u64);
    fn end_voting(ref self: T);
    fn extend_deadline(ref self: T, extra_time: u64);
}
```

#### Functions

##### `commit_vote`
- **Purpose**: Submit a vote commitment during the commit phase
- **Parameters**: 
  - `commitment`: felt252 - Hash of vote + salt
- **Returns**: None
- **Access**: Any address
- **Requirements**: Voting must be active

##### `reveal_vote`
- **Purpose**: Reveal the actual vote during the reveal phase
- **Parameters**:
  - `vote`: u32 - The actual vote value (0 or 1)
  - `salt`: felt252 - Random salt used in commitment
- **Returns**: None
- **Access**: Any address
- **Requirements**: Valid commitment must exist

##### `get_results`
- **Purpose**: Get current voting results
- **Parameters**: None
- **Returns**: Array<u32> - [yes_votes, no_votes]
- **Access**: Read-only

##### `get_voting_status`
- **Purpose**: Check if voting is currently active
- **Parameters**: None
- **Returns**: bool - true if voting is active
- **Access**: Read-only

##### `start_voting`
- **Purpose**: Start a new voting session
- **Parameters**:
  - `duration`: u64 - Voting duration in seconds
- **Returns**: None
- **Access**: Admin only

##### `end_voting`
- **Purpose**: End the current voting session
- **Parameters**: None
- **Returns**: None
- **Access**: Admin only

##### `extend_deadline`
- **Purpose**: Extend the voting deadline
- **Parameters**:
  - `extra_time`: u64 - Additional time in seconds
- **Returns**: None
- **Access**: Admin only

## Advanced Modules

### Voting Module Interfaces

#### IBasicVoting
```cairo
pub trait IBasicVoting<T> {
    fn cast_vote(ref self: T, choice: u32);
    fn get_vote_count(self: @T, choice: u32) -> u32;
    fn get_total_votes(self: @T) -> u32;
    fn get_voting_results(self: @T) -> Array<u32>;
}
```

#### IQuadraticVoting
```cairo
pub trait IQuadraticVoting<T> {
    fn cast_quadratic_vote(ref self: T, choice: u32, credits: u32);
    fn get_vote_weight(self: @T, choice: u32) -> u32;
    fn get_credit_balance(self: @T, voter: felt252) -> u32;
    fn allocate_credits(ref self: T, voter: felt252, credits: u32);
}
```

#### IDelegatedVoting
```cairo
pub trait IDelegatedVoting<T> {
    fn cast_vote(ref self: T, choice: u32);
    fn delegate_vote(ref self: T, delegate: felt252);
    fn undelegate_vote(ref self: T);
    fn get_delegated_power(self: @T, voter: felt252) -> u32;
    fn get_delegation_info(self: @T, voter: felt252) -> Array<felt252>;
}
```

#### ITimelockedVoting
```cairo
pub trait ITimelockedVoting<T> {
    fn commit_vote(ref self: T, commitment: felt252);
    fn reveal_vote(ref self: T, vote: u32, salt: felt252);
    fn get_vote_count(self: @T, choice: u32) -> u32;
    fn get_commitment_status(self: @T, commitment: felt252) -> bool;
}
```

#### IMultiphaseVoting
```cairo
pub trait IMultiphaseVoting<T> {
    fn commit_vote(ref self: T, commitment: felt252);
    fn reveal_vote(ref self: T, vote: u32, salt: felt252);
    fn advance_phase(ref self: T);
    fn get_current_phase(self: @T) -> u32;
    fn get_voting_summary(self: @T) -> Array<felt252>;
}
```

### Governance Module Interfaces

#### IDAOGovernance
```cairo
pub trait IDAOGovernance<T> {
    fn create_proposal(ref self: T, title: felt252, description: felt252);
    fn vote_on_proposal(ref self: T, proposal_id: u32, vote: bool);
    fn execute_proposal(ref self: T, proposal_id: u32);
    fn get_proposal_status(self: @T, proposal_id: u32) -> Array<felt252>;
}
```

#### IMultisigAdmin
```cairo
pub trait IMultisigAdmin<T> {
    fn add_signer(ref self: T, signer: felt252);
    fn remove_signer(ref self: T, signer: felt252);
    fn submit_transaction(ref self: T, target: felt252, data: Array<felt252>);
    fn confirm_transaction(ref self: T, transaction_id: u32);
    fn execute_transaction(ref self: T, transaction_id: u32);
}
```

#### IEmergencyControls
```cairo
pub trait IEmergencyControls<T> {
    fn trigger_emergency_pause(ref self: T, reason: felt252);
    fn lift_emergency_pause(ref self: T);
    fn is_emergency_active(self: @T) -> bool;
    fn get_emergency_info(self: @T) -> Array<felt252>;
}
```

#### IProposalSystem
```cairo
pub trait IProposalSystem<T> {
    fn create_proposal(ref self: T, proposal_type: u32, title: felt252, content: felt252);
    fn support_proposal(ref self: T, proposal_id: u32);
    fn execute_proposal(ref self: T, proposal_id: u32);
    fn get_proposal_details(self: @T, proposal_id: u32) -> Array<felt252>;
}
```

### Security Module Interfaces

#### IZKProofs
```cairo
pub trait IZKProofs<T> {
    fn submit_proof(ref self: T, proof: Array<felt252>, public_inputs: Array<felt252>);
    fn verify_proof(ref self: T, proof_id: u32);
    fn get_proof_status(self: @T, proof_id: u32) -> Array<felt252>;
    fn revoke_proof(ref self: T, proof_id: u32);
}
```

#### IAccessControl
```cairo
pub trait IAccessControl<T> {
    fn grant_role(ref self: T, role: felt252, account: felt252);
    fn revoke_role(ref self: T, role: felt252, account: felt252);
    fn has_role(self: @T, role: felt252, account: felt252) -> bool;
    fn get_role_members(self: @T, role: felt252) -> Array<felt252>;
}
```

#### IQuantumResistance
```cairo
pub trait IQuantumResistance<T> {
    fn enable_quantum_resistance(ref self: T, algorithm: u32);
    fn get_quantum_security_level(self: @T) -> u32;
    fn upgrade_quantum_algorithm(ref self: T, new_algorithm: u32);
    fn is_quantum_secure(self: @T) -> bool;
}
```

#### IAuditTrail
```cairo
pub trait IAuditTrail<T> {
    fn log_event(ref self: T, event_type: felt252, data: Array<felt252>);
    fn get_audit_log(self: @T, start_index: u32, limit: u32) -> Array<felt252>;
    fn get_event_count(self: @T) -> u32;
    fn clear_audit_log(ref self: T);
}
```

### AI Module Interfaces

#### IConsciousnessBased
```cairo
pub trait IConsciousnessBased<T> {
    fn initialize_consciousness(ref self: T, consciousness_level: u32);
    fn get_consciousness_state(self: @T, user: felt252) -> Array<felt252>;
    fn evolve_consciousness(ref self: T, user: felt252, experience: felt252);
    fn get_collective_consciousness(self: @T) -> Array<felt252>;
}
```

#### IMLAssistants
```cairo
pub trait IMLAssistants<T> {
    fn create_assistant(ref self: T, name: felt252, model_type: u32);
    fn query_assistant(self: @T, assistant_id: u32, query: felt252) -> felt252;
    fn train_assistant(ref self: T, assistant_id: u32, data: Array<felt252>);
    fn get_assistant_performance(self: @T, assistant_id: u32) -> Array<felt252>;
}
```

#### INeuralGovernance
```cairo
pub trait INeuralGovernance<T> {
    fn initialize_neural_network(ref self: T, layers: Array<u32>);
    fn train_network(ref self: T, input_data: Array<felt252>, expected_output: Array<felt252>);
    fn predict_governance(self: @T, input: Array<felt252>) -> Array<felt252>;
    fn get_network_weights(self: @T) -> Array<felt252>;
}
```

#### ISwarmIntelligence
```cairo
pub trait ISwarmIntelligence<T> {
    fn initialize_swarm(ref self: T, swarm_size: u32);
    fn add_agent(ref self: T, agent_id: u32, capabilities: Array<felt252>);
    fn coordinate_swarm(ref self: T, task: felt252) -> Array<felt252>;
    fn get_swarm_consensus(self: @T) -> felt252;
}
```

### Analytics Module Interfaces

#### IInsightsEngine
```cairo
pub trait IInsightsEngine<T> {
    fn generate_insights(ref self: T, data_type: u32, parameters: Array<felt252>);
    fn get_insights(self: @T, insight_id: u32) -> Array<felt252>;
    fn analyze_trends(self: @T, time_range: (u64, u64)) -> Array<felt252>;
    fn get_insight_summary(self: @T) -> Array<felt252>;
}
```

#### IMLPredictions
```cairo
pub trait IMLPredictions<T> {
    fn train_model(ref self: T, model_id: u32, training_data: Array<felt252>);
    fn make_prediction(self: @T, model_id: u32, input_data: Array<felt252>) -> Array<felt252>;
    fn get_model_accuracy(self: @T, model_id: u32) -> u32;
    fn update_model(ref self: T, model_id: u32, new_weights: Array<felt252>);
}
```

#### IPerformanceMetrics
```cairo
pub trait IPerformanceMetrics<T> {
    fn record_metric(ref self: T, metric_name: felt252, value: u32, timestamp: u64);
    fn get_metrics(self: @T, metric_name: felt252) -> Array<u32>;
    fn calculate_performance_score(self: @T, time_period: u32) -> u32;
    fn get_top_performers(self: @T, metric_type: u32, limit: u32) -> Array<felt252>;
}
```

#### IVotingPatterns
```cairo
pub trait IVotingPatterns<T> {
    fn analyze_voting_pattern(self: @T, voter: felt252) -> Array<felt252>;
    fn detect_anomalies(self: @T, time_window: u64) -> Array<felt252>;
    fn predict_voter_behavior(self: @T, voter: felt252) -> Array<felt252>;
    fn get_pattern_summary(self: @T) -> Array<felt252>;
}
```

### Optimization Module Interfaces

#### IGasOptimization
```cairo
pub trait IGasOptimization<T> {
    fn optimize_gas_usage(ref self: T, operation: u32);
    fn get_gas_savings(self: @T, operation_type: u32) -> u32;
    fn batch_operations(ref self: T, operations: Array<u32>);
    fn get_optimization_report(self: @T) -> Array<felt252>;
}
```

#### IBatchProcessing
```cairo
pub trait IBatchProcessing<T> {
    fn create_batch(ref self: T, batch_size: u32);
    fn add_to_batch(ref self: T, batch_id: u32, operation: felt252);
    fn execute_batch(ref self: T, batch_id: u32);
    fn get_batch_status(self: @T, batch_id: u32) -> Array<felt252>;
}
```

#### ILazyLoading
```cairo
pub trait ILazyLoading<T> {
    fn enable_lazy_loading(ref self: T, data_type: u32);
    fn load_data_on_demand(self: @T, data_key: felt252) -> Array<felt252>;
    fn preload_critical_data(ref self: T, keys: Array<felt252>);
    fn get_loading_stats(self: @T) -> Array<felt252>;
}
```

#### IStoragePacking
```cairo
pub trait IStoragePacking<T> {
    fn pack_storage(ref self: T, data: Array<felt252>);
    fn unpack_storage(self: @T, packed_data: felt252) -> Array<felt252>;
    fn get_packing_efficiency(self: @T) -> u32;
    fn optimize_storage_layout(ref self: T);
}
```

### Quantum Module Interfaces

#### IQuantumResistance
```cairo
pub trait IQuantumResistance<T> {
    fn enable_quantum_resistance(ref self: T, algorithm: u32);
    fn get_quantum_security_level(self: @T) -> u32;
    fn upgrade_quantum_algorithm(ref self: T, new_algorithm: u32);
    fn is_quantum_secure(self: @T) -> bool;
}
```

#### IQuantumEntanglement
```cairo
pub trait IQuantumEntanglement<T> {
    fn create_entangled_pair(ref self: T, data: felt252);
    fn get_entangled_state(self: @T, pair_id: u32) -> Array<felt252>;
    fn measure_entanglement(self: @T, pair_id: u32) -> felt252;
    fn get_entanglement_stats(self: @T) -> Array<felt252>;
}
```

#### IDNACryptography
```cairo
pub trait IDNACryptography<T> {
    fn encode_dna_sequence(ref self: T, sequence: Array<felt252>);
    fn decode_dna_sequence(self: @T, encoded_data: felt252) -> Array<felt252>;
    fn verify_dna_signature(self: @T, data: felt252, signature: felt252) -> bool;
    fn get_dna_security_metrics(self: @T) -> Array<felt252>;
}
```

#### ITimeDilated
```cairo
pub trait ITimeDilated<T> {
    fn enable_time_dilation(ref self: T, dilation_factor: u32);
    fn get_dilated_time(self: @T, original_time: u64) -> u64;
    fn create_time_locked_vault(ref self: T, data: felt252, unlock_time: u64);
    fn is_time_vault_locked(self: @T, vault_id: u32) -> bool;
}
```

### Interoperability Module Interfaces

#### ICrossChainBridge
```cairo
pub trait ICrossChainBridge<T> {
    fn create_bridge(ref self: T, target_chain: u32, target_address: felt252);
    fn bridge_tokens(ref self: T, amount: u32, target_chain: u32);
    fn claim_bridged_tokens(ref self: T, bridge_id: u32);
    fn get_bridge_status(self: @T, bridge_id: u32) -> Array<felt252>;
}
```

#### IMultiChainVoting
```cairo
pub trait IMultiChainVoting<T> {
    fn create_cross_chain_proposal(ref self: T, chains: Array<u32>, proposal_data: felt252);
    fn vote_cross_chain(ref self: T, proposal_id: u32, vote: bool, source_chain: u32);
    fn execute_cross_chain_decision(ref self: T, proposal_id: u32);
    fn get_cross_chain_results(self: @T, proposal_id: u32) -> Array<felt252>;
}
```

#### IBridgeSecurity
```cairo
pub trait IBridgeSecurity<T> {
    fn enable_bridge_security(ref self: T, security_level: u32);
    fn validate_bridge_transaction(self: @T, tx_hash: felt252) -> bool;
    fn freeze_suspicious_bridge(ref self: T, bridge_id: u32);
    fn get_security_report(self: @T) -> Array<felt252>;
}
```

#### IChainAbstraction
```cairo
pub trait IChainAbstraction<T> {
    fn register_chain(ref self: T, chain_id: u32, chain_config: Array<felt252>);
    fn abstract_transaction(ref self: T, target_chain: u32, transaction_data: Array<felt252>);
    fn get_supported_chains(self: @T) -> Array<u32>;
    fn get_chain_status(self: @T, chain_id: u32) -> Array<felt252>;
}
```

## Data Structures

### Storage Structures

#### Core Storage
```cairo
#[storage]
struct Storage {
    admin: felt252,
    voting_active: bool,
    start_time: u64,
    end_time: u64,
    yes_votes: u32,
    no_votes: u32,
}
```

#### Voting Storage
```cairo
#[storage]
struct VotingStorage {
    vote_counts: Map<u32, u32>,
    total_votes: u32,
    voting_active: bool,
    start_time: u64,
    end_time: u64,
}
```

#### Governance Storage
```cairo
#[storage]
struct GovernanceStorage {
    proposals: Map<u32, Proposal>,
    votes: Map<(u32, felt252), bool>,
    next_proposal_id: u32,
    quorum: u32,
    execution_delay: u64,
}
```

### Custom Types

#### Proposal
```cairo
#[derive(Drop)]
struct Proposal {
    id: u32,
    title: felt252,
    description: felt252,
    created_at: u64,
    votes_for: u32,
    votes_against: u32,
    executed: bool,
}
```

#### Transaction
```cairo
#[derive(Drop)]
struct Transaction {
    id: u32,
    target: felt252,
    data: Array<felt252>,
    created_at: u64,
    executed: bool,
}
```

#### MLModel
```cairo
#[derive(Drop)]
struct MLModel {
    id: u32,
    weights: Array<felt252>,
    accuracy: u32,
    last_trained: u64,
    model_type: u32,
}
```

## Error Codes

| Code | Description | Action |
|------|-------------|---------|
| 100 | Voting not active | Wait for voting to start |
| 101 | Invalid commitment | Check commitment calculation |
| 102 | Already voted | Cannot vote twice |
| 103 | Voting ended | Voting period is over |
| 200 | Admin access required | Use admin account |
| 201 | Invalid parameters | Check input values |
| 300 | Insufficient permissions | Request required role |
| 301 | Operation not allowed | Check contract state |

## Events

### Voting Events
```cairo
#[event]
fn VoteCommitted(voter: felt252, commitment: felt252);

#[event]
fn VoteRevealed(voter: felt252, vote: u32);

#[event]
fn VotingStarted(duration: u64);

#[event]
fn VotingEnded();
```

### Governance Events
```cairo
#[event]
fn ProposalCreated(proposal_id: u32, title: felt252);

#[event]
fn VoteCast(proposal_id: u32, voter: felt252, vote: bool);

#[event]
fn ProposalExecuted(proposal_id: u32);
```

### Security Events
```cairo
#[event]
fn RoleGranted(role: felt252, account: felt252);

#[event]
fn RoleRevoked(role: felt252, account: felt252);

#[event]
fn EmergencyPaused(reason: felt252);
```

## Usage Examples

### Basic Voting
```cairo
// Commit a vote
veritas.commit_vote(my_commitment);

// Reveal the vote
veritas.reveal_vote(1, my_salt);

// Get results
let results = veritas.get_results();
```

### Governance
```cairo
// Create a proposal
governance.create_proposal('New Feature', 'Implement new voting mechanism');

// Vote on proposal
governance.vote_on_proposal(1, true);

// Execute proposal
governance.execute_proposal(1);
```

### Security
```cairo
// Grant role
access_control.grant_role('ADMIN', user_address);

// Check role
let has_admin = access_control.has_role('ADMIN', user_address);
```

## Deployment

### Constructor Parameters
```cairo
fn constructor(ref self: ContractState, admin: felt252)
```

### Initial Setup
1. Deploy contract with admin address
2. Set up voting parameters
3. Configure security roles
4. Initialize AI models (optional)

## Integration

### JavaScript/TypeScript
```typescript
import { Contract } from 'starknet';

const veritas = new Contract(contractAddress, abi);

// Commit vote
await veritas.commit_vote(commitment);

// Reveal vote
await veritas.reveal_vote(vote, salt);
```

### Python
```python
from starknet import Contract

veritas = Contract(contract_address, abi)

# Commit vote
await veritas.commit_vote(commitment)

# Reveal vote
await veritas.reveal_vote(vote, salt)
```

## Security Considerations

1. **Commitment Security**: Use cryptographically secure random salts
2. **Access Control**: Implement proper role-based permissions
3. **Input Validation**: Validate all user inputs
4. **Event Logging**: Maintain comprehensive audit trails
5. **Quantum Resistance**: Enable quantum-safe algorithms when needed

## Best Practices

1. **Gas Optimization**: Use batch operations when possible
2. **Error Handling**: Implement proper error handling and user feedback
3. **Testing**: Comprehensive testing of all functions
4. **Documentation**: Keep API documentation up to date
5. **Monitoring**: Implement monitoring and alerting systems

---

For more information, visit [docs.veritas.io](https://docs.veritas.io)
