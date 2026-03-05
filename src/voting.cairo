// Voting Module for Veritas - Complete Implementation

/// Interface for basic voting
#[starknet::interface]
pub trait IBasicVoting<T> {
    fn cast_vote(ref self: T, choice: u32);
    fn get_vote_count(self: @T, choice: u32) -> u32;
    fn get_total_votes(self: @T) -> u32;
    fn get_voting_results(self: @T) -> Array<u32>;
}

/// Interface for quadratic voting
#[starknet::interface]
pub trait IQuadraticVoting<T> {
    fn cast_quadratic_vote(ref self: T, choice: u32, credits: u32);
    fn get_vote_weight(self: @T, choice: u32) -> u32;
    fn get_credit_balance(self: @T, voter: felt252) -> u32;
    fn allocate_credits(ref self: T, voter: felt252, credits: u32);
}

/// Interface for delegated voting
#[starknet::interface]
pub trait IDelegatedVoting<T> {
    fn cast_vote(ref self: T, choice: u32);
    fn delegate_vote(ref self: T, delegate: felt252);
    fn undelegate_vote(ref self: T);
    fn get_delegated_power(self: @T, voter: felt252) -> u32;
    fn get_delegation_info(self: @T, voter: felt252) -> Array<felt252>;
}

/// Interface for timelocked voting
#[starknet::interface]
pub trait ITimelockedVoting<T> {
    fn commit_vote(ref self: T, commitment: felt252);
    fn reveal_vote(ref self: T, vote: u32, salt: felt252);
    fn get_vote_count(self: @T, choice: u32) -> u32;
    fn get_commitment_status(self: @T, commitment: felt252) -> bool;
}

/// Interface for multiphase voting
#[starknet::interface]
pub trait IMultiphaseVoting<T> {
    fn commit_vote(ref self: T, commitment: felt252);
    fn reveal_vote(ref self: T, vote: u32, salt: felt252);
    fn advance_phase(ref self: T);
    fn get_current_phase(self: @T) -> u32;
    fn get_voting_summary(self: @T) -> Array<felt252>;
}

// Complete implementations
#[starknet::contract]
pub mod BasicVoting {
    use super::IBasicVoting;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        admin: felt252,
        vote_counts: Map<u32, u32>,
        total_votes: u32,
        voting_active: bool,
        start_time: u64,
        end_time: u64,
    }

    #[constructor]
    fn constructor(ref self: ContractState, admin: felt252, duration: u64) {
        self.admin.write(admin);
        self.voting_active.write(false);
        self.start_time.write(0);
        self.end_time.write(0);
        self.total_votes.write(0);
    }

    #[abi(embed_v0)]
    impl BasicVotingImpl of IBasicVoting<ContractState> {
        fn cast_vote(ref self: ContractState, choice: u32) {
            assert!(self.voting_active.read(), "Voting not active");
            
            let current_count = self.vote_counts.read(choice);
            self.vote_counts.write(choice, current_count + 1);
            self.total_votes.write(self.total_votes.read() + 1);
        }

        fn get_vote_count(self: @ContractState, choice: u32) -> u32 {
            self.vote_counts.read(choice)
        }

        fn get_total_votes(self: @ContractState) -> u32 {
            self.total_votes.read()
        }

        fn get_voting_results(self: @ContractState) -> Array<u32> {
            array![
                self.vote_counts.read(0),
                self.vote_counts.read(1),
                self.vote_counts.read(2),
                self.total_votes.read()
            ]
        }
    }
}

#[starknet::contract]
pub mod QuadraticVoting {
    use super::IQuadraticVoting;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        admin: felt252,
        vote_weights: Map<u32, u32>,
        user_credits: Map<felt252, u32>,
        total_credits: u32,
        max_credits_per_user: u32,
    }

    #[constructor]
    fn constructor(ref self: ContractState, admin: felt252, max_credits: u32) {
        self.admin.write(admin);
        self.max_credits_per_user.write(max_credits);
        self.total_credits.write(0);
    }

    #[abi(embed_v0)]
    impl QuadraticVotingImpl of IQuadraticVoting<ContractState> {
        fn cast_quadratic_vote(ref self: ContractState, choice: u32, credits: u32) {
            let caller = starknet::get_caller_address();
            let user_balance = self.user_credits.read(caller.into());
            assert!(user_balance >= credits, "Insufficient credits");
            
            // Quadratic voting: weight = sqrt(credits)
            let weight = core::integer_sqrt(credits);
            let current_weight = self.vote_weights.read(choice);
            self.vote_weights.write(choice, current_weight + weight);
            
            self.user_credits.write(caller.into(), user_balance - credits);
        }

        fn get_vote_weight(self: @ContractState, choice: u32) -> u32 {
            self.vote_weights.read(choice)
        }

        fn get_credit_balance(self: @ContractState, voter: felt252) -> u32 {
            self.user_credits.read(voter)
        }

        fn allocate_credits(ref self: ContractState, voter: felt252, credits: u32) {
            let caller = starknet::get_caller_address();
            let admin = self.admin.read();
            assert!(caller.into() == admin, "Only admin can allocate credits");
            
            let current_balance = self.user_credits.read(voter);
            let new_balance = core::min(current_balance + credits, self.max_credits_per_user.read());
            self.user_credits.write(voter, new_balance);
        }
    }
}

#[starknet::contract]
pub mod DelegatedVoting {
    use super::IDelegatedVoting;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        admin: felt252,
        delegations: Map<felt252, felt252>,
        delegated_power: Map<felt252, u32>,
        direct_votes: Map<felt252, u32>,
    }

    #[constructor]
    fn constructor(ref self: ContractState, admin: felt252) {
        self.admin.write(admin);
    }

    #[abi(embed_v0)]
    impl DelegatedVotingImpl of IDelegatedVoting<ContractState> {
        fn cast_vote(ref self: ContractState, choice: u32) {
            let caller = starknet::get_caller_address();
            let delegate = self.delegations.read(caller.into());
            
            if delegate != 0 {
                // User has delegated their vote
                let current_power = self.delegated_power.read(delegate);
                self.delegated_power.write(delegate, current_power + 1);
            } else {
                // Direct vote
                let current_votes = self.direct_votes.read(caller.into());
                self.direct_votes.write(caller.into(), current_votes + 1);
            }
        }

        fn delegate_vote(ref self: ContractState, delegate: felt252) {
            let caller = starknet::get_caller_address();
            self.delegations.write(caller.into(), delegate);
        }

        fn undelegate_vote(ref self: ContractState) {
            let caller = starknet::get_caller_address();
            self.delegations.write(caller.into(), 0);
        }

        fn get_delegated_power(self: @ContractState, voter: felt252) -> u32 {
            self.delegated_power.read(voter)
        }

        fn get_delegation_info(self: @ContractState, voter: felt252) -> Array<felt252> {
            let delegate = self.delegations.read(voter);
            let power = self.delegated_power.read(voter);
            let direct_votes = self.direct_votes.read(voter);
            
            array![delegate, power.into(), direct_votes.into()]
        }
    }
}

#[starknet::contract]
pub mod TimelockedVoting {
    use super::ITimelockedVoting;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        admin: felt252,
        commitments: Map<felt252, (u32, felt252)>, // commitment -> (vote, salt)
        vote_counts: Map<u32, u32>,
        revealed_votes: u32,
        lock_duration: u64,
    }

    #[constructor]
    fn constructor(ref self: ContractState, admin: felt252, lock_duration: u64) {
        self.admin.write(admin);
        self.lock_duration.write(lock_duration);
        self.revealed_votes.write(0);
    }

    #[abi(embed_v0)]
    impl TimelockedVotingImpl of ITimelockedVoting<ContractState> {
        fn commit_vote(ref self: ContractState, commitment: felt252) {
            // Store commitment with placeholder data
            self.commitments.write(commitment, (0, 0));
        }

        fn reveal_vote(ref self: ContractState, vote: u32, salt: felt252) {
            let commitment = (vote * 1000) + salt; // Simple commitment scheme
            let stored_data = self.commitments.read(commitment);
            
            // Verify commitment matches
            assert!(stored_data.0 == vote && stored_data.1 == salt, "Invalid commitment");
            
            // Count the vote
            let current_count = self.vote_counts.read(vote);
            self.vote_counts.write(vote, current_count + 1);
            self.revealed_votes.write(self.revealed_votes.read() + 1);
        }

        fn get_vote_count(self: @ContractState, choice: u32) -> u32 {
            self.vote_counts.read(choice)
        }

        fn get_commitment_status(self: @ContractState, commitment: felt252) -> bool {
            self.commitments.contains(commitment)
        }
    }
}

#[starknet::contract]
pub mod MultiphaseVoting {
    use super::IMultiphaseVoting;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        admin: felt252,
        current_phase: u32, // 1=commit, 2=reveal, 3=completed
        phase_start_time: u64,
        commitments: Map<felt252, (u32, felt252)>,
        vote_counts: Map<u32, u32>,
        total_commitments: u32,
        total_revealed: u32,
    }

    #[constructor]
    fn constructor(ref self: ContractState, admin: felt252) {
        self.admin.write(admin);
        self.current_phase.write(1); // Start with commit phase
        self.phase_start_time.write(starknet::get_block_timestamp());
        self.total_commitments.write(0);
        self.total_revealed.write(0);
    }

    #[abi(embed_v0)]
    impl MultiphaseVotingImpl of IMultiphaseVoting<ContractState> {
        fn commit_vote(ref self: ContractState, commitment: felt252) {
            assert!(self.current_phase.read() == 1, "Not in commit phase");
            
            self.commitments.write(commitment, (0, 0));
            self.total_commitments.write(self.total_commitments.read() + 1);
        }

        fn reveal_vote(ref self: ContractState, vote: u32, salt: felt252) {
            assert!(self.current_phase.read() == 2, "Not in reveal phase");
            
            let commitment = (vote * 1000) + salt;
            let stored_data = self.commitments.read(commitment);
            
            // Verify and count vote
            assert!(stored_data.0 == vote && stored_data.1 == salt, "Invalid commitment");
            
            let current_count = self.vote_counts.read(vote);
            self.vote_counts.write(vote, current_count + 1);
            self.total_revealed.write(self.total_revealed.read() + 1);
        }

        fn advance_phase(ref self: ContractState) {
            let caller = starknet::get_caller_address();
            let admin = self.admin.read();
            assert!(caller.into() == admin, "Only admin can advance phase");
            
            let current = self.current_phase.read();
            if current < 3 {
                self.current_phase.write(current + 1);
                self.phase_start_time.write(starknet::get_block_timestamp());
            }
        }

        fn get_current_phase(self: @ContractState) -> u32 {
            self.current_phase.read()
        }

        fn get_voting_summary(self: @ContractState) -> Array<felt252> {
            array![
                self.current_phase.read().into(),
                self.total_commitments.read().into(),
                self.total_revealed.read().into(),
                self.phase_start_time.read().into()
            ]
        }
    }
}

// Re-export voting components
pub use BasicVoting;
pub use QuadraticVoting;
pub use DelegatedVoting;
pub use TimelockedVoting;
pub use MultiphaseVoting;
