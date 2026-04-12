// Governance Module for Veritas — DAO proposals + emergency controls

/// DAO Governance with quorum enforcement and execution delay
#[starknet::interface]
pub trait IDAOGovernance<T> {
    fn create_proposal(ref self: T, title: felt252, description: felt252);
    fn vote_on_proposal(ref self: T, proposal_id: u32, support: bool);
    fn execute_proposal(ref self: T, proposal_id: u32);
    fn get_proposal_votes(self: @T, proposal_id: u32) -> (u32, u32);
    fn get_proposal_count(self: @T) -> u32;
    fn is_proposal_executed(self: @T, proposal_id: u32) -> bool;
}

/// Emergency pause with admin control
#[starknet::interface]
pub trait IEmergencyControls<T> {
    fn trigger_emergency_pause(ref self: T, reason: felt252);
    fn lift_emergency_pause(ref self: T);
    fn is_emergency_active(self: @T) -> bool;
    fn get_pause_reason(self: @T) -> felt252;
}

// ===================================================================
// DAO Governance
// ===================================================================
#[starknet::contract]
pub mod DAOGovernance {
    use super::IDAOGovernance;
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };

    #[storage]
    struct Storage {
        admin: starknet::ContractAddress,
        quorum: u32,
        execution_delay: u64,
        next_proposal_id: u32,
        proposal_title: Map<u32, felt252>,
        proposal_description: Map<u32, felt252>,
        proposal_created_at: Map<u32, u64>,
        proposal_votes_for: Map<u32, u32>,
        proposal_votes_against: Map<u32, u32>,
        proposal_executed: Map<u32, bool>,
        voter_has_voted: Map<(u32, starknet::ContractAddress), bool>,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        admin: starknet::ContractAddress,
        quorum: u32,
        execution_delay: u64,
    ) {
        self.admin.write(admin);
        self.quorum.write(quorum);
        self.execution_delay.write(execution_delay);
        self.next_proposal_id.write(0);
    }

    #[abi(embed_v0)]
    impl DAOGovernanceImpl of IDAOGovernance<ContractState> {
        fn create_proposal(ref self: ContractState, title: felt252, description: felt252) {
            let id = self.next_proposal_id.read();
            self.proposal_title.write(id, title);
            self.proposal_description.write(id, description);
            self.proposal_created_at.write(id, starknet::get_block_timestamp());
            self.proposal_votes_for.write(id, 0);
            self.proposal_votes_against.write(id, 0);
            self.proposal_executed.write(id, false);
            self.next_proposal_id.write(id + 1);
        }

        fn vote_on_proposal(ref self: ContractState, proposal_id: u32, support: bool) {
            let caller = starknet::get_caller_address();
            assert(proposal_id < self.next_proposal_id.read(), 'Proposal does not exist');
            assert(!self.proposal_executed.read(proposal_id), 'Already executed');
            assert(!self.voter_has_voted.read((proposal_id, caller)), 'Already voted');

            self.voter_has_voted.write((proposal_id, caller), true);

            if support {
                let v = self.proposal_votes_for.read(proposal_id);
                self.proposal_votes_for.write(proposal_id, v + 1);
            } else {
                let v = self.proposal_votes_against.read(proposal_id);
                self.proposal_votes_against.write(proposal_id, v + 1);
            }
        }

        fn execute_proposal(ref self: ContractState, proposal_id: u32) {
            assert(proposal_id < self.next_proposal_id.read(), 'Proposal does not exist');
            assert(!self.proposal_executed.read(proposal_id), 'Already executed');

            let votes_for = self.proposal_votes_for.read(proposal_id);
            let votes_against = self.proposal_votes_against.read(proposal_id);
            let total = votes_for + votes_against;
            assert(total >= self.quorum.read(), 'Quorum not reached');
            assert(votes_for > votes_against, 'Proposal rejected');

            let created = self.proposal_created_at.read(proposal_id);
            let now = starknet::get_block_timestamp();
            assert(now >= created + self.execution_delay.read(), 'Execution delay not met');

            self.proposal_executed.write(proposal_id, true);
        }

        fn get_proposal_votes(self: @ContractState, proposal_id: u32) -> (u32, u32) {
            (
                self.proposal_votes_for.read(proposal_id),
                self.proposal_votes_against.read(proposal_id),
            )
        }

        fn get_proposal_count(self: @ContractState) -> u32 {
            self.next_proposal_id.read()
        }

        fn is_proposal_executed(self: @ContractState, proposal_id: u32) -> bool {
            self.proposal_executed.read(proposal_id)
        }
    }
}

// ===================================================================
// Emergency Controls
// ===================================================================
#[starknet::contract]
pub mod EmergencyControls {
    use super::IEmergencyControls;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        admin: starknet::ContractAddress,
        emergency_active: bool,
        reason: felt252,
        paused_at: u64,
    }

    #[constructor]
    fn constructor(ref self: ContractState, admin: starknet::ContractAddress) {
        self.admin.write(admin);
        self.emergency_active.write(false);
    }

    #[abi(embed_v0)]
    impl EmergencyControlsImpl of IEmergencyControls<ContractState> {
        fn trigger_emergency_pause(ref self: ContractState, reason: felt252) {
            let caller = starknet::get_caller_address();
            assert(caller == self.admin.read(), 'Admin access required');
            self.emergency_active.write(true);
            self.reason.write(reason);
            self.paused_at.write(starknet::get_block_timestamp());
        }

        fn lift_emergency_pause(ref self: ContractState) {
            let caller = starknet::get_caller_address();
            assert(caller == self.admin.read(), 'Admin access required');
            self.emergency_active.write(false);
            self.reason.write(0);
        }

        fn is_emergency_active(self: @ContractState) -> bool {
            self.emergency_active.read()
        }

        fn get_pause_reason(self: @ContractState) -> felt252 {
            self.reason.read()
        }
    }
}
