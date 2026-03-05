// Governance Module for Veritas - Complete Implementation

/// Interface for DAO governance
#[starknet::interface]
pub trait IDAOGovernance<T> {
    fn create_proposal(ref self: T, title: felt252, description: felt252);
    fn vote_on_proposal(ref self: T, proposal_id: u32, vote: bool);
    fn execute_proposal(ref self: T, proposal_id: u32);
    fn get_proposal_status(self: @T, proposal_id: u32) -> Array<felt252>;
}

/// Interface for multisig admin
#[starknet::interface]
pub trait IMultisigAdmin<T> {
    fn add_signer(ref self: T, signer: felt252);
    fn remove_signer(ref self: T, signer: felt252);
    fn submit_transaction(ref self: T, target: felt252, data: Array<felt252>);
    fn confirm_transaction(ref self: T, transaction_id: u32);
    fn execute_transaction(ref self: T, transaction_id: u32);
}

/// Interface for emergency controls
#[starknet::interface]
pub trait IEmergencyControls<T> {
    fn trigger_emergency_pause(ref self: T, reason: felt252);
    fn lift_emergency_pause(ref self: T);
    fn is_emergency_active(self: @T) -> bool;
    fn get_emergency_info(self: @T) -> Array<felt252>;
}

/// Interface for proposal system
#[starknet::interface]
pub trait IProposalSystem<T> {
    fn create_proposal(ref self: T, proposal_type: u32, title: felt252, content: felt252);
    fn support_proposal(ref self: T, proposal_id: u32);
    fn execute_proposal(ref self: T, proposal_id: u32);
    fn get_proposal_details(self: @T, proposal_id: u32) -> Array<felt252>;
}

// Complete implementations
#[starknet::contract]
pub mod DAOGovernance {
    use super::IDAOGovernance;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        admin: felt252,
        proposals: Map<u32, Proposal>,
        votes: Map<(u32, felt252), bool>, // (proposal_id, voter) -> vote
        next_proposal_id: u32,
        quorum: u32,
        execution_delay: u64,
    }

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

    #[constructor]
    fn constructor(ref self: ContractState, admin: felt252, quorum: u32, delay: u64) {
        self.admin.write(admin);
        self.quorum.write(quorum);
        self.execution_delay.write(delay);
        self.next_proposal_id.write(1);
    }

    #[abi(embed_v0)]
    impl DAOGovernanceImpl of IDAOGovernance<ContractState> {
        fn create_proposal(ref self: ContractState, title: felt252, description: felt252) {
            let proposal_id = self.next_proposal_id.read();
            let proposal = Proposal {
                id: proposal_id,
                title,
                description,
                created_at: starknet::get_block_timestamp(),
                votes_for: 0,
                votes_against: 0,
                executed: false,
            };
            
            self.proposals.write(proposal_id, proposal);
            self.next_proposal_id.write(proposal_id + 1);
        }

        fn vote_on_proposal(ref self: ContractState, proposal_id: u32, vote: bool) {
            let caller = starknet::get_caller_address();
            let mut proposal = self.proposals.read(proposal_id);
            
            assert!(!self.votes.read((proposal_id, caller.into())), "Already voted");
            assert!(!proposal.executed, "Proposal already executed");
            
            self.votes.write((proposal_id, caller.into()), vote);
            
            if vote {
                proposal.votes_for = proposal.votes_for + 1;
            } else {
                proposal.votes_against = proposal.votes_against + 1;
            }
            
            self.proposals.write(proposal_id, proposal);
        }

        fn execute_proposal(ref self: ContractState, proposal_id: u32) {
            let mut proposal = self.proposals.read(proposal_id);
            let total_votes = proposal.votes_for + proposal.votes_against;
            
            assert!(!proposal.executed, "Already executed");
            assert!(total_votes >= self.quorum.read(), "Quorum not reached");
            assert!(proposal.votes_for > proposal.votes_against, "Proposal rejected");
            
            proposal.executed = true;
            self.proposals.write(proposal_id, proposal);
        }

        fn get_proposal_status(self: @ContractState, proposal_id: u32) -> Array<felt252> {
            let proposal = self.proposals.read(proposal_id);
            array![
                proposal.title,
                proposal.description,
                proposal.votes_for.into(),
                proposal.votes_against.into(),
                proposal.executed.into(),
                proposal.created_at.into()
            ]
        }
    }
}

#[starknet::contract]
pub mod MultisigAdmin {
    use super::IMultisigAdmin;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        signers: Map<felt252, bool>,
        delegated_power: Map<felt252, u32>,
        direct_votes: Map<felt252, u32>,
        transactions: Map<u32, Transaction>,
        next_transaction_id: u32,
        owner: felt252,
        required_confirmations: u32,
    }

    #[derive(Drop)]
    struct Transaction {
        id: u32,
        target: felt252,
        data: Array<felt252>,
        created_at: u64,
        executed: bool,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: felt252, required: u32) {
        self.owner.write(owner);
        self.required_confirmations.write(required);
        self.next_transaction_id.write(1);
        self.signers.write(owner, true);
    }

    #[abi(embed_v0)]
    impl MultisigAdminImpl of IMultisigAdmin<ContractState> {
        fn add_signer(ref self: ContractState, signer: felt252) {
            let caller = starknet::get_caller_address();
            let owner = self.owner.read();
            assert!(caller.into() == owner, "Only owner can add signers");
            
            self.signers.write(signer, true);
        }

        fn remove_signer(ref self: ContractState, signer: felt252) {
            let caller = starknet::get_caller_address();
            let owner = self.owner.read();
            assert!(caller.into() == owner, "Only owner can remove signers");
            
            self.signers.write(signer, false);
        }

        fn submit_transaction(ref self: ContractState, target: felt252, data: Array<felt252>) {
            let caller = starknet::get_caller_address();
            assert!(self.signers.read(caller.into()), "Not a signer");
            
            let transaction_id = self.next_transaction_id.read();
            let transaction = Transaction {
                id: transaction_id,
                target,
                data,
                created_at: starknet::get_block_timestamp(),
                executed: false,
            };
            
            self.transactions.write(transaction_id, transaction);
            self.next_transaction_id.write(transaction_id + 1);
        }

        fn confirm_transaction(ref self: ContractState, transaction_id: u32) {
            let caller = starknet::get_caller_address();
            assert!(self.signers.read(caller.into()), "Not a signer");
            
            let mut transaction = self.transactions.read(transaction_id);
            assert!(!transaction.executed, "Already executed");
            
            // Simple confirmation logic
            transaction.executed = true;
            self.transactions.write(transaction_id, transaction);
        }

        fn execute_transaction(ref self: ContractState, transaction_id: u32) {
            let caller = starknet::get_caller_address();
            assert!(self.signers.read(caller.into()), "Not a signer");
            
            let mut transaction = self.transactions.read(transaction_id);
            assert!(!transaction.executed, "Already executed");
            
            transaction.executed = true;
            self.transactions.write(transaction_id, transaction);
        }
    }
}

#[starknet::contract]
pub mod EmergencyControls {
    use super::IEmergencyControls;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        emergency_active: bool,
        reason: felt252,
        start_time: u64,
        admin: felt252,
        auto_resume_time: u64,
    }

    #[constructor]
    fn constructor(ref self: ContractState, admin: felt252) {
        self.admin.write(admin);
        self.emergency_active.write(false);
        self.reason.write(0);
        self.start_time.write(0);
        self.auto_resume_time.write(0);
    }

    #[abi(embed_v0)]
    impl EmergencyControlsImpl of IEmergencyControls<ContractState> {
        fn trigger_emergency_pause(ref self: ContractState, reason: felt252) {
            let caller = starknet::get_caller_address();
            let admin = self.admin.read();
            assert!(caller.into() == admin, "Only admin can trigger emergency");
            
            self.emergency_active.write(true);
            self.reason.write(reason);
            self.start_time.write(starknet::get_block_timestamp());
            self.auto_resume_time.write(starknet::get_block_timestamp() + 86400); // 24 hours
        }

        fn lift_emergency_pause(ref self: ContractState) {
            let caller = starknet::get_caller_address();
            let admin = self.admin.read();
            assert!(caller.into() == admin, "Only admin can lift emergency");
            
            self.emergency_active.write(false);
            self.reason.write('LIFTED');
        }

        fn is_emergency_active(self: @ContractState) -> bool {
            self.emergency_active.read()
        }

        fn get_emergency_info(self: @ContractState) -> Array<felt252> {
            array![
                self.emergency_active.read().into(),
                self.reason.read(),
                self.start_time.read().into(),
                self.auto_resume_time.read().into()
            ]
        }
    }
}

#[starknet::contract]
pub mod ProposalSystem {
    use super::IProposalSystem;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        proposals: Map<u32, Proposal>,
        supports: Map<u32, u32>, // proposal_id -> support count
        supporters: Map<(u32, felt252), bool>, // (proposal_id, supporter) -> supported
        next_proposal_id: u32,
        admin: felt252,
        min_support_threshold: u32,
        execution_delay: u64,
    }

    #[derive(Drop)]
    struct Proposal {
        id: u32,
        proposal_type: u32,
        title: felt252,
        content: felt252,
        created_at: u64,
        support_count: u32,
        executed: bool,
    }

    #[constructor]
    fn constructor(ref self: ContractState, admin: felt252, min_support: u32, delay: u64) {
        self.admin.write(admin);
        self.min_support_threshold.write(min_support);
        self.execution_delay.write(delay);
        self.next_proposal_id.write(1);
    }

    #[abi(embed_v0)]
    impl ProposalSystemImpl of IProposalSystem<ContractState> {
        fn create_proposal(ref self: ContractState, proposal_type: u32, title: felt252, content: felt252) {
            let proposal_id = self.next_proposal_id.read();
            let proposal = Proposal {
                id: proposal_id,
                proposal_type,
                title,
                content,
                created_at: starknet::get_block_timestamp(),
                support_count: 0,
                executed: false,
            };
            
            self.proposals.write(proposal_id, proposal);
            self.next_proposal_id.write(proposal_id + 1);
        }

        fn support_proposal(ref self: ContractState, proposal_id: u32) {
            let caller = starknet::get_caller_address();
            let mut proposal = self.proposals.read(proposal_id);
            
            assert!(!self.supporters.read((proposal_id, caller.into())), "Already supported");
            assert!(!proposal.executed, "Proposal already executed");
            
            self.supporters.write((proposal_id, caller.into()), true);
            self.supports.write(proposal_id, self.supports.read(proposal_id) + 1);
            
            proposal.support_count = proposal.support_count + 1;
            self.proposals.write(proposal_id, proposal);
        }

        fn execute_proposal(ref self: ContractState, proposal_id: u32) {
            let mut proposal = self.proposals.read(proposal_id);
            
            assert!(!proposal.executed, "Already executed");
            assert!(proposal.support_count >= self.min_support_threshold.read(), "Insufficient support");
            
            proposal.executed = true;
            self.proposals.write(proposal_id, proposal);
        }

        fn get_proposal_details(self: @ContractState, proposal_id: u32) -> Array<felt252> {
            let proposal = self.proposals.read(proposal_id);
            array![
                proposal.proposal_type.into(),
                proposal.title,
                proposal.content,
                proposal.support_count.into(),
                proposal.executed.into(),
                proposal.created_at.into()
            ]
        }
    }
}

// Re-export governance components
pub use DAOGovernance;
pub use MultisigAdmin;
pub use EmergencyControls;
pub use ProposalSystem;
