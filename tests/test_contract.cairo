use core::pedersen::pedersen;
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare, start_cheat_caller_address,
    stop_cheat_caller_address, start_cheat_block_timestamp, stop_cheat_block_timestamp,
};
use starknet::{ContractAddress, contract_address_const};
use veritas::{IVeritasDispatcher, IVeritasDispatcherTrait};

// Admin address as felt252 — must match contract_address_const::<999>().into()
const ADMIN_FELT: felt252 = 999;

fn deploy(
    num_options: u8, commit_dur: u64, reveal_dur: u64,
) -> (ContractAddress, IVeritasDispatcher) {
    let contract = declare("Veritas").unwrap().contract_class();
    let calldata = array![
        ADMIN_FELT,
        num_options.into(),
        commit_dur.into(),
        reveal_dur.into(),
    ];
    let (addr, _) = contract.deploy(@calldata).unwrap();
    (addr, IVeritasDispatcher { contract_address: addr })
}

fn deploy_default() -> (ContractAddress, IVeritasDispatcher) {
    deploy(5, 100, 100) // 5 options, commit 0-99, reveal 100-199
}

// =====================================================================
// HAPPY PATH
// =====================================================================

#[test]
fn test_full_voting_flow() {
    let (ca, d) = deploy_default();
    let voter = contract_address_const::<123>();

    // Commit phase
    start_cheat_caller_address(ca, voter);
    let vote: u8 = 1;
    let salt: felt252 = 12345;
    d.commit_vote(pedersen(vote.into(), salt));
    stop_cheat_caller_address(ca);

    assert(d.get_total_commits() == 1, 'commits should be 1');
    assert(d.get_phase() == 0, 'should be commit phase');

    // Reveal phase
    start_cheat_block_timestamp(ca, 100);
    assert(d.get_phase() == 1, 'should be reveal phase');

    start_cheat_caller_address(ca, voter);
    d.reveal_vote(vote, salt);
    stop_cheat_caller_address(ca);

    assert(d.get_tally(1) == 1, 'tally(1) should be 1');
    assert(d.get_tally(0) == 0, 'tally(0) should be 0');
    assert(d.get_total_reveals() == 1, 'reveals should be 1');

    // After reveal_end
    start_cheat_block_timestamp(ca, 200);
    assert(d.get_phase() == 2, 'should be ended');
}

#[test]
fn test_multiple_voters_different_options() {
    let (ca, d) = deploy_default();

    // 3 voters commit
    let v1 = contract_address_const::<11>();
    let v2 = contract_address_const::<22>();
    let v3 = contract_address_const::<33>();

    start_cheat_caller_address(ca, v1);
    d.commit_vote(pedersen(0_u8.into(), 1000));
    stop_cheat_caller_address(ca);

    start_cheat_caller_address(ca, v2);
    d.commit_vote(pedersen(1_u8.into(), 2000));
    stop_cheat_caller_address(ca);

    start_cheat_caller_address(ca, v3);
    d.commit_vote(pedersen(4_u8.into(), 3000));
    stop_cheat_caller_address(ca);

    assert(d.get_total_commits() == 3, 'should have 3 commits');

    // Reveal phase
    start_cheat_block_timestamp(ca, 100);

    start_cheat_caller_address(ca, v1);
    d.reveal_vote(0, 1000);
    stop_cheat_caller_address(ca);

    start_cheat_caller_address(ca, v2);
    d.reveal_vote(1, 2000);
    stop_cheat_caller_address(ca);

    start_cheat_caller_address(ca, v3);
    d.reveal_vote(4, 3000);
    stop_cheat_caller_address(ca);

    assert(d.get_tally(0) == 1, 'tally(0)');
    assert(d.get_tally(1) == 1, 'tally(1)');
    assert(d.get_tally(4) == 1, 'tally(4)');
    assert(d.get_total_reveals() == 3, 'reveals');
}

// =====================================================================
// INV-1: UNIQUENESS
// =====================================================================

#[test]
#[should_panic(expected: 'Already Voted')]
fn test_double_commit() {
    let (ca, d) = deploy_default();
    let voter = contract_address_const::<123>();
    start_cheat_caller_address(ca, voter);
    d.commit_vote(pedersen(1_u8.into(), 111));
    d.commit_vote(pedersen(1_u8.into(), 222)); // panics
}

#[test]
#[should_panic(expected: 'Already revealed')]
fn test_double_reveal() {
    let (ca, d) = deploy_default();
    let voter = contract_address_const::<123>();
    start_cheat_caller_address(ca, voter);
    d.commit_vote(pedersen(1_u8.into(), 111));
    start_cheat_block_timestamp(ca, 100);
    d.reveal_vote(1, 111);
    d.reveal_vote(1, 111); // panics
}

// =====================================================================
// INV-2: CRYPTOGRAPHIC BINDING
// =====================================================================

#[test]
#[should_panic(expected: 'Fraudulent Reveal')]
fn test_wrong_salt() {
    let (ca, d) = deploy_default();
    let voter = contract_address_const::<123>();
    start_cheat_caller_address(ca, voter);
    d.commit_vote(pedersen(1_u8.into(), 12345));
    start_cheat_block_timestamp(ca, 100);
    d.reveal_vote(1, 99999);
}

#[test]
#[should_panic(expected: 'Fraudulent Reveal')]
fn test_wrong_vote() {
    let (ca, d) = deploy_default();
    let voter = contract_address_const::<123>();
    start_cheat_caller_address(ca, voter);
    d.commit_vote(pedersen(1_u8.into(), 12345));
    start_cheat_block_timestamp(ca, 100);
    d.reveal_vote(2, 12345);
}

// =====================================================================
// INV-3: CONSISTENCY — reveal without commit
// =====================================================================

#[test]
#[should_panic(expected: 'No commitment found')]
fn test_reveal_without_commit() {
    let (ca, d) = deploy_default();
    let voter = contract_address_const::<456>();
    start_cheat_caller_address(ca, voter);
    start_cheat_block_timestamp(ca, 100);
    d.reveal_vote(1, 12345);
}

// =====================================================================
// INV-4: TEMPORAL INTEGRITY
// =====================================================================

#[test]
#[should_panic(expected: 'Commit phase ended')]
fn test_commit_after_deadline() {
    let (ca, d) = deploy_default();
    let voter = contract_address_const::<123>();
    start_cheat_caller_address(ca, voter);
    start_cheat_block_timestamp(ca, 100);
    d.commit_vote(pedersen(1_u8.into(), 111));
}

#[test]
#[should_panic(expected: 'Reveal phase not started')]
fn test_reveal_too_early() {
    let (ca, d) = deploy_default();
    let voter = contract_address_const::<123>();
    start_cheat_caller_address(ca, voter);
    d.commit_vote(pedersen(1_u8.into(), 111));
    // still in commit phase (time=0 < 100)
    d.reveal_vote(1, 111);
}

#[test]
#[should_panic(expected: 'Reveal phase ended')]
fn test_reveal_after_reveal_deadline() {
    let (ca, d) = deploy_default();
    let voter = contract_address_const::<123>();
    start_cheat_caller_address(ca, voter);
    d.commit_vote(pedersen(1_u8.into(), 111));
    start_cheat_block_timestamp(ca, 200); // past reveal_end
    d.reveal_vote(1, 111);
}

// =====================================================================
// INV-5: ADMIN / EMERGENCY PAUSE
// =====================================================================

#[test]
fn test_admin_pause_unpause() {
    let (ca, d) = deploy_default();
    let admin = contract_address_const::<999>();

    assert(!d.is_paused(), 'should not be paused');

    start_cheat_caller_address(ca, admin);
    d.emergency_pause();
    assert(d.is_paused(), 'should be paused');
    assert(d.get_phase() == 3, 'phase should be 3 (paused)');

    d.emergency_unpause();
    assert(!d.is_paused(), 'should be unpaused');
    stop_cheat_caller_address(ca);
}

#[test]
#[should_panic(expected: 'Contract is paused')]
fn test_commit_while_paused() {
    let (ca, d) = deploy_default();
    let admin = contract_address_const::<999>();
    let voter = contract_address_const::<123>();

    start_cheat_caller_address(ca, admin);
    d.emergency_pause();
    stop_cheat_caller_address(ca);

    start_cheat_caller_address(ca, voter);
    d.commit_vote(pedersen(1_u8.into(), 111));
}

#[test]
#[should_panic(expected: 'Contract is paused')]
fn test_reveal_while_paused() {
    let (ca, d) = deploy_default();
    let admin = contract_address_const::<999>();
    let voter = contract_address_const::<123>();

    // Commit first
    start_cheat_caller_address(ca, voter);
    d.commit_vote(pedersen(1_u8.into(), 111));
    stop_cheat_caller_address(ca);

    // Admin pauses
    start_cheat_caller_address(ca, admin);
    d.emergency_pause();
    stop_cheat_caller_address(ca);

    // Try to reveal
    start_cheat_block_timestamp(ca, 100);
    start_cheat_caller_address(ca, voter);
    d.reveal_vote(1, 111);
}

#[test]
#[should_panic(expected: 'Admin access required')]
fn test_non_admin_cannot_pause() {
    let (ca, d) = deploy_default();
    let rando = contract_address_const::<666>();
    start_cheat_caller_address(ca, rando);
    d.emergency_pause();
}

#[test]
fn test_admin_transfer() {
    let (ca, d) = deploy_default();
    let admin = contract_address_const::<999>();
    let new_admin_felt: felt252 = 888;
    let new_admin = contract_address_const::<888>();

    start_cheat_caller_address(ca, admin);
    d.transfer_admin(new_admin_felt);
    stop_cheat_caller_address(ca);

    assert(d.get_admin() == new_admin_felt, 'admin should be new');

    // New admin can pause
    start_cheat_caller_address(ca, new_admin);
    d.emergency_pause();
    assert(d.is_paused(), 'new admin should pause');
    stop_cheat_caller_address(ca);
}

#[test]
#[should_panic(expected: 'Admin access required')]
fn test_old_admin_cannot_act_after_transfer() {
    let (ca, d) = deploy_default();
    let admin = contract_address_const::<999>();

    start_cheat_caller_address(ca, admin);
    d.transfer_admin(888);
    stop_cheat_caller_address(ca);

    // Old admin tries to pause
    start_cheat_caller_address(ca, admin);
    d.emergency_pause();
}

// =====================================================================
// INV-6: VOTE OPTION VALIDITY
// =====================================================================

#[test]
#[should_panic(expected: 'Invalid vote option')]
fn test_vote_option_out_of_range() {
    let (ca, d) = deploy(2, 100, 100); // only options 0 and 1
    let voter = contract_address_const::<123>();
    start_cheat_caller_address(ca, voter);
    d.commit_vote(pedersen(2_u8.into(), 111)); // vote=2 but max is 2 (exclusive)
    start_cheat_block_timestamp(ca, 100);
    d.reveal_vote(2, 111);
}

#[test]
fn test_vote_option_boundary() {
    let (ca, d) = deploy(3, 100, 100); // options 0, 1, 2
    let voter = contract_address_const::<123>();
    start_cheat_caller_address(ca, voter);
    d.commit_vote(pedersen(2_u8.into(), 111)); // vote=2, max valid
    start_cheat_block_timestamp(ca, 100);
    d.reveal_vote(2, 111);
    assert(d.get_tally(2) == 1, 'tally(2) should be 1');
}

// =====================================================================
// VIEW FUNCTIONS
// =====================================================================

#[test]
fn test_view_functions() {
    let (ca, d) = deploy(5, 100, 100);
    assert(d.get_num_options() == 5, 'num_options');
    assert(d.get_commit_end() == 100, 'commit_end');
    assert(d.get_reveal_end() == 200, 'reveal_end');
    assert(d.get_admin() == ADMIN_FELT, 'admin');
    assert(d.get_total_commits() == 0, 'commits');
    assert(d.get_total_reveals() == 0, 'reveals');
}
