use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare, start_cheat_block_timestamp,
    start_cheat_caller_address, stop_cheat_caller_address,
};
use starknet::{ContractAddress, contract_address_const};
use veritas::governance::{
    IDAOGovernanceDispatcher, IDAOGovernanceDispatcherTrait, IEmergencyControlsDispatcher,
    IEmergencyControlsDispatcherTrait,
};

const ADMIN_FELT: felt252 = 999;

fn deploy_governance(quorum: u32, delay: u64) -> (ContractAddress, IDAOGovernanceDispatcher) {
    let contract = declare("DAOGovernance").unwrap().contract_class();
    let admin = contract_address_const::<999>();
    let mut calldata = array![];
    admin.serialize(ref calldata);
    calldata.append(quorum.into());
    calldata.append(delay.into());
    let (addr, _) = contract.deploy(@calldata).unwrap();
    (addr, IDAOGovernanceDispatcher { contract_address: addr })
}

fn deploy_emergency() -> (ContractAddress, IEmergencyControlsDispatcher) {
    let contract = declare("EmergencyControls").unwrap().contract_class();
    let admin = contract_address_const::<999>();
    let mut calldata = array![];
    admin.serialize(ref calldata);
    let (addr, _) = contract.deploy(@calldata).unwrap();
    (addr, IEmergencyControlsDispatcher { contract_address: addr })
}

// =====================================================================
// DAO GOVERNANCE
// =====================================================================

#[test]
fn test_create_and_vote_proposal() {
    let (ca, d) = deploy_governance(2, 0); // quorum=2, no delay

    // Create proposal
    let proposer = contract_address_const::<111>();
    start_cheat_caller_address(ca, proposer);
    d.create_proposal('Title', 'Description');
    stop_cheat_caller_address(ca);

    assert(d.get_proposal_count() == 1, 'should have 1 proposal');

    // Vote for
    let v1 = contract_address_const::<222>();
    start_cheat_caller_address(ca, v1);
    d.vote_on_proposal(0, true);
    stop_cheat_caller_address(ca);

    let v2 = contract_address_const::<333>();
    start_cheat_caller_address(ca, v2);
    d.vote_on_proposal(0, false);
    stop_cheat_caller_address(ca);

    let (votes_for, votes_against) = d.get_proposal_votes(0);
    assert(votes_for == 1, 'votes_for');
    assert(votes_against == 1, 'votes_against');
}

#[test]
fn test_execute_proposal_with_quorum() {
    let (ca, d) = deploy_governance(2, 0);

    let proposer = contract_address_const::<111>();
    start_cheat_caller_address(ca, proposer);
    d.create_proposal('Title', 'Desc');
    stop_cheat_caller_address(ca);

    // 2 votes for, 0 against — meets quorum of 2
    let v1 = contract_address_const::<222>();
    start_cheat_caller_address(ca, v1);
    d.vote_on_proposal(0, true);
    stop_cheat_caller_address(ca);

    let v2 = contract_address_const::<333>();
    start_cheat_caller_address(ca, v2);
    d.vote_on_proposal(0, true);
    stop_cheat_caller_address(ca);

    d.execute_proposal(0);
    assert(d.is_proposal_executed(0), 'should be executed');
}

#[test]
#[should_panic(expected: 'Quorum not reached')]
fn test_execute_without_quorum() {
    let (ca, d) = deploy_governance(5, 0); // quorum=5

    let proposer = contract_address_const::<111>();
    start_cheat_caller_address(ca, proposer);
    d.create_proposal('Title', 'Desc');
    stop_cheat_caller_address(ca);

    let v1 = contract_address_const::<222>();
    start_cheat_caller_address(ca, v1);
    d.vote_on_proposal(0, true);
    stop_cheat_caller_address(ca);

    d.execute_proposal(0); // only 1 vote, quorum is 5
}

#[test]
#[should_panic(expected: 'Proposal rejected')]
fn test_execute_rejected_proposal() {
    let (ca, d) = deploy_governance(2, 0);

    let proposer = contract_address_const::<111>();
    start_cheat_caller_address(ca, proposer);
    d.create_proposal('Title', 'Desc');
    stop_cheat_caller_address(ca);

    // 1 for, 1 against — tied = rejected (need strictly more for)
    let v1 = contract_address_const::<222>();
    start_cheat_caller_address(ca, v1);
    d.vote_on_proposal(0, true);
    stop_cheat_caller_address(ca);

    let v2 = contract_address_const::<333>();
    start_cheat_caller_address(ca, v2);
    d.vote_on_proposal(0, false);
    stop_cheat_caller_address(ca);

    d.execute_proposal(0);
}

#[test]
#[should_panic(expected: 'Already voted')]
fn test_double_vote_on_proposal() {
    let (ca, d) = deploy_governance(2, 0);

    let proposer = contract_address_const::<111>();
    start_cheat_caller_address(ca, proposer);
    d.create_proposal('Title', 'Desc');
    stop_cheat_caller_address(ca);

    let v1 = contract_address_const::<222>();
    start_cheat_caller_address(ca, v1);
    d.vote_on_proposal(0, true);
    d.vote_on_proposal(0, false); // double vote
}

#[test]
#[should_panic(expected: 'Already executed')]
fn test_double_execute() {
    let (ca, d) = deploy_governance(1, 0);

    let proposer = contract_address_const::<111>();
    start_cheat_caller_address(ca, proposer);
    d.create_proposal('Title', 'Desc');
    d.vote_on_proposal(0, true);
    stop_cheat_caller_address(ca);

    d.execute_proposal(0);
    d.execute_proposal(0);
}

#[test]
#[should_panic(expected: 'Execution delay not met')]
fn test_execution_delay() {
    let (ca, d) = deploy_governance(1, 1000); // 1000s delay

    let proposer = contract_address_const::<111>();
    start_cheat_caller_address(ca, proposer);
    d.create_proposal('Title', 'Desc');
    d.vote_on_proposal(0, true);
    stop_cheat_caller_address(ca);

    // Try to execute immediately — should fail
    d.execute_proposal(0);
}

#[test]
fn test_execution_delay_met() {
    let (ca, d) = deploy_governance(1, 100);

    let proposer = contract_address_const::<111>();
    start_cheat_caller_address(ca, proposer);
    d.create_proposal('Title', 'Desc');
    d.vote_on_proposal(0, true);
    stop_cheat_caller_address(ca);

    start_cheat_block_timestamp(ca, 100);
    d.execute_proposal(0);
    assert(d.is_proposal_executed(0), 'should be executed');
}

// =====================================================================
// EMERGENCY CONTROLS
// =====================================================================

#[test]
fn test_emergency_pause_unpause() {
    let (ca, d) = deploy_emergency();
    let admin = contract_address_const::<999>();

    assert(!d.is_emergency_active(), 'should not be active');

    start_cheat_caller_address(ca, admin);
    d.trigger_emergency_pause('EXPLOIT');
    assert(d.is_emergency_active(), 'should be active');
    assert(d.get_pause_reason() == 'EXPLOIT', 'reason');

    d.lift_emergency_pause();
    assert(!d.is_emergency_active(), 'should be lifted');
    stop_cheat_caller_address(ca);
}

#[test]
#[should_panic(expected: 'Admin access required')]
fn test_non_admin_cannot_pause_emergency() {
    let (ca, d) = deploy_emergency();
    let rando = contract_address_const::<666>();
    start_cheat_caller_address(ca, rando);
    d.trigger_emergency_pause('HACK');
}
