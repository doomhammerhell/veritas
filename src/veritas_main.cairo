// Veritas main contract — secure commit-reveal blind voting
//
// Invariants enforced:
//   INV-1  Uniqueness    — one commit per voter, one reveal per voter
//   INV-2  Binding       — Pedersen(vote, salt) must match stored commitment
//   INV-3  Consistency   — reveals ≤ commits, tally = sum of valid reveals
//   INV-4  Temporality   — commits in [0, commit_end), reveals in [commit_end, reveal_end)
//   INV-5  Finality      — after reveal_end no state changes; admin can pause anytime
//   INV-6  Vote validity — vote option must be in [0, num_options)

/// Main Veritas interface
#[starknet::interface]
pub trait IVeritas<T> {
    // --- Voter actions ---
    fn commit_vote(ref self: T, commitment: felt252);
    fn reveal_vote(ref self: T, vote: u8, salt: felt252);

    // --- Admin actions ---
    fn emergency_pause(ref self: T);
    fn emergency_unpause(ref self: T);
    fn transfer_admin(ref self: T, new_admin: felt252);

    // --- View ---
    fn get_tally(self: @T, vote: u8) -> u32;
    fn get_total_commits(self: @T) -> u32;
    fn get_total_reveals(self: @T) -> u32;
    fn get_num_options(self: @T) -> u8;
    fn get_commit_end(self: @T) -> u64;
    fn get_reveal_end(self: @T) -> u64;
    fn is_paused(self: @T) -> bool;
    fn get_admin(self: @T) -> felt252;
    fn get_phase(self: @T) -> u8; // 0=commit, 1=reveal, 2=ended, 3=paused
}

#[starknet::contract]
pub mod Veritas {
    use super::IVeritas;
    use core::pedersen::pedersen;
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };

    // We use has_committed bool to track state, not a sentinel on the commitment
    // value. This eliminates the EMPTY_COMMITMENT=0 edge case entirely:
    // even if pedersen(vote,salt) == 0, the flow still works because we check
    // has_committed and has_revealed as separate booleans.

    #[storage]
    struct Storage {
        admin: felt252,
        paused: bool,
        num_options: u8,
        commit_end: u64,
        reveal_end: u64,
        commitments: Map<starknet::ContractAddress, felt252>,
        has_committed: Map<starknet::ContractAddress, bool>,
        has_revealed: Map<starknet::ContractAddress, bool>,
        tally: Map<u8, u32>,
        total_commits: u32,
        total_reveals: u32,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        VoteCommitted: VoteCommitted,
        VoteRevealed: VoteRevealed,
        EmergencyPaused: EmergencyPaused,
        EmergencyUnpaused: EmergencyUnpaused,
        AdminTransferred: AdminTransferred,
    }

    #[derive(Drop, starknet::Event)]
    struct VoteCommitted {
        #[key]
        voter: starknet::ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct VoteRevealed {
        #[key]
        voter: starknet::ContractAddress,
        vote: u8,
    }

    #[derive(Drop, starknet::Event)]
    struct EmergencyPaused {
        admin: felt252,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct EmergencyUnpaused {
        admin: felt252,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct AdminTransferred {
        old_admin: felt252,
        new_admin: felt252,
    }

    /// Constructor
    /// admin        — admin address (as felt252 for simple caller comparison)
    /// num_options  — number of valid vote options [0..num_options)
    /// commit_dur   — commit phase duration in seconds
    /// reveal_dur   — reveal phase duration in seconds
    #[constructor]
    fn constructor(
        ref self: ContractState,
        admin: felt252,
        num_options: u8,
        commit_dur: u64,
        reveal_dur: u64,
    ) {
        assert(num_options >= 2, 'Need at least 2 options');
        assert(commit_dur > 0, 'Commit duration must be > 0');
        assert(reveal_dur > 0, 'Reveal duration must be > 0');

        let now = starknet::get_block_timestamp();
        self.admin.write(admin);
        self.paused.write(false);
        self.num_options.write(num_options);
        self.commit_end.write(now + commit_dur);
        self.reveal_end.write(now + commit_dur + reveal_dur);
        self.total_commits.write(0);
        self.total_reveals.write(0);
    }

    #[abi(embed_v0)]
    impl VeritasImpl of IVeritas<ContractState> {
        // =============================================================
        // COMMIT — only during commit phase, not paused
        // =============================================================
        fn commit_vote(ref self: ContractState, commitment: felt252) {
            assert(!self.paused.read(), 'Contract is paused');

            let caller = starknet::get_caller_address();
            let now = starknet::get_block_timestamp();

            // INV-4: temporal — must be in commit phase
            assert(now < self.commit_end.read(), 'Commit phase ended');

            // INV-1: uniqueness
            assert(!self.has_committed.read(caller), 'Already Voted');

            self.commitments.write(caller, commitment);
            self.has_committed.write(caller, true);
            self.total_commits.write(self.total_commits.read() + 1);

            self.emit(VoteCommitted { voter: caller });
        }

        // =============================================================
        // REVEAL — only during reveal phase, not paused
        // =============================================================
        fn reveal_vote(ref self: ContractState, vote: u8, salt: felt252) {
            assert(!self.paused.read(), 'Contract is paused');

            let caller = starknet::get_caller_address();
            let now = starknet::get_block_timestamp();

            // INV-4: temporal — must be in reveal phase
            assert(now >= self.commit_end.read(), 'Reveal phase not started');
            assert(now < self.reveal_end.read(), 'Reveal phase ended');

            // INV-1: must have committed, must not have revealed
            assert(self.has_committed.read(caller), 'No commitment found');
            assert(!self.has_revealed.read(caller), 'Already revealed');

            // INV-6: vote option validity
            assert(vote < self.num_options.read(), 'Invalid vote option');

            // INV-2: cryptographic binding
            let stored = self.commitments.read(caller);
            let computed = pedersen(vote.into(), salt);
            assert(computed == stored, 'Fraudulent Reveal');

            // Mark as revealed
            self.has_revealed.write(caller, true);

            // Count the vote
            let current = self.tally.read(vote);
            self.tally.write(vote, current + 1);
            self.total_reveals.write(self.total_reveals.read() + 1);

            self.emit(VoteRevealed { voter: caller, vote });
        }

        // =============================================================
        // ADMIN — emergency controls
        // =============================================================
        fn emergency_pause(ref self: ContractState) {
            let caller: felt252 = starknet::get_caller_address().into();
            assert(caller == self.admin.read(), 'Admin access required');
            assert(!self.paused.read(), 'Already paused');
            self.paused.write(true);
            self
                .emit(
                    EmergencyPaused {
                        admin: caller, timestamp: starknet::get_block_timestamp(),
                    },
                );
        }

        fn emergency_unpause(ref self: ContractState) {
            let caller: felt252 = starknet::get_caller_address().into();
            assert(caller == self.admin.read(), 'Admin access required');
            assert(self.paused.read(), 'Not paused');
            self.paused.write(false);
            self
                .emit(
                    EmergencyUnpaused {
                        admin: caller, timestamp: starknet::get_block_timestamp(),
                    },
                );
        }

        fn transfer_admin(ref self: ContractState, new_admin: felt252) {
            let caller: felt252 = starknet::get_caller_address().into();
            assert(caller == self.admin.read(), 'Admin access required');
            assert(new_admin != 0, 'Invalid admin address');
            let old = self.admin.read();
            self.admin.write(new_admin);
            self.emit(AdminTransferred { old_admin: old, new_admin });
        }

        // =============================================================
        // VIEW
        // =============================================================
        fn get_tally(self: @ContractState, vote: u8) -> u32 {
            self.tally.read(vote)
        }

        fn get_total_commits(self: @ContractState) -> u32 {
            self.total_commits.read()
        }

        fn get_total_reveals(self: @ContractState) -> u32 {
            self.total_reveals.read()
        }

        fn get_num_options(self: @ContractState) -> u8 {
            self.num_options.read()
        }

        fn get_commit_end(self: @ContractState) -> u64 {
            self.commit_end.read()
        }

        fn get_reveal_end(self: @ContractState) -> u64 {
            self.reveal_end.read()
        }

        fn is_paused(self: @ContractState) -> bool {
            self.paused.read()
        }

        fn get_admin(self: @ContractState) -> felt252 {
            self.admin.read()
        }

        fn get_phase(self: @ContractState) -> u8 {
            if self.paused.read() {
                return 3; // paused
            }
            let now = starknet::get_block_timestamp();
            if now < self.commit_end.read() {
                0 // commit phase
            } else if now < self.reveal_end.read() {
                1 // reveal phase
            } else {
                2 // ended
            }
        }
    }
}
