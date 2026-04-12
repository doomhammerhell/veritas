use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare, start_cheat_caller_address,
    stop_cheat_caller_address,
};
use starknet::{ContractAddress, contract_address_const};
use veritas::security::{IAccessControlDispatcher, IAccessControlDispatcherTrait};
use veritas::security::{IAuditTrailDispatcher, IAuditTrailDispatcherTrait};

fn deploy_access_control() -> (ContractAddress, IAccessControlDispatcher) {
    let contract = declare("AccessControl").unwrap().contract_class();
    let admin = contract_address_const::<999>();
    let mut calldata = array![];
    admin.serialize(ref calldata);
    let (addr, _) = contract.deploy(@calldata).unwrap();
    (addr, IAccessControlDispatcher { contract_address: addr })
}

fn deploy_audit_trail() -> (ContractAddress, IAuditTrailDispatcher) {
    let contract = declare("AuditTrail").unwrap().contract_class();
    let admin = contract_address_const::<999>();
    let mut calldata = array![];
    admin.serialize(ref calldata);
    let (addr, _) = contract.deploy(@calldata).unwrap();
    (addr, IAuditTrailDispatcher { contract_address: addr })
}

// =====================================================================
// ACCESS CONTROL
// =====================================================================

#[test]
fn test_admin_has_role_on_deploy() {
    let (_ca, d) = deploy_access_control();
    let admin = contract_address_const::<999>();
    assert(d.has_role('ADMIN', admin), 'admin should have ADMIN role');
}

#[test]
fn test_grant_and_check_role() {
    let (ca, d) = deploy_access_control();
    let admin = contract_address_const::<999>();
    let user = contract_address_const::<123>();

    assert(!d.has_role('VOTER', user), 'should not have role');

    start_cheat_caller_address(ca, admin);
    d.grant_role('VOTER', user);
    stop_cheat_caller_address(ca);

    assert(d.has_role('VOTER', user), 'should have role');
}

#[test]
fn test_revoke_role() {
    let (ca, d) = deploy_access_control();
    let admin = contract_address_const::<999>();
    let user = contract_address_const::<123>();

    start_cheat_caller_address(ca, admin);
    d.grant_role('VOTER', user);
    assert(d.has_role('VOTER', user), 'should have role');

    d.revoke_role('VOTER', user);
    assert(!d.has_role('VOTER', user), 'should not have role');
    stop_cheat_caller_address(ca);
}

#[test]
#[should_panic(expected: 'Admin access required')]
fn test_non_admin_cannot_grant() {
    let (ca, d) = deploy_access_control();
    let rando = contract_address_const::<666>();
    let user = contract_address_const::<123>();

    start_cheat_caller_address(ca, rando);
    d.grant_role('VOTER', user);
}

#[test]
fn test_transfer_admin() {
    let (ca, d) = deploy_access_control();
    let admin = contract_address_const::<999>();
    let new_admin = contract_address_const::<888>();

    start_cheat_caller_address(ca, admin);
    d.transfer_admin(new_admin);
    stop_cheat_caller_address(ca);

    assert(d.get_admin() == new_admin, 'admin should be new');
    assert(!d.has_role('ADMIN', admin), 'old admin no ADMIN role');
    assert(d.has_role('ADMIN', new_admin), 'new admin has ADMIN role');

    // New admin can grant roles
    let user = contract_address_const::<123>();
    start_cheat_caller_address(ca, new_admin);
    d.grant_role('VOTER', user);
    stop_cheat_caller_address(ca);
    assert(d.has_role('VOTER', user), 'user should have role');
}

#[test]
#[should_panic(expected: 'Admin access required')]
fn test_old_admin_cannot_grant_after_transfer() {
    let (ca, d) = deploy_access_control();
    let admin = contract_address_const::<999>();
    let new_admin = contract_address_const::<888>();
    let user = contract_address_const::<123>();

    start_cheat_caller_address(ca, admin);
    d.transfer_admin(new_admin);
    stop_cheat_caller_address(ca);

    start_cheat_caller_address(ca, admin);
    d.grant_role('VOTER', user); // old admin, should fail
}

// =====================================================================
// AUDIT TRAIL
// =====================================================================

#[test]
fn test_log_and_count() {
    let (ca, d) = deploy_audit_trail();
    let actor = contract_address_const::<123>();

    assert(d.get_log_count() == 0, 'should be 0');

    d.log_action('VOTE_COMMITTED', actor);
    assert(d.get_log_count() == 1, 'should be 1');

    d.log_action('VOTE_REVEALED', actor);
    assert(d.get_log_count() == 2, 'should be 2');
}
