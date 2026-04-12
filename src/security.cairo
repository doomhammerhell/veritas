// Security module for Veritas — Real access control and audit trail

/// Role-based access control with proper per-role, per-account tracking
#[starknet::interface]
pub trait IAccessControl<T> {
    fn grant_role(ref self: T, role: felt252, account: starknet::ContractAddress);
    fn revoke_role(ref self: T, role: felt252, account: starknet::ContractAddress);
    fn has_role(self: @T, role: felt252, account: starknet::ContractAddress) -> bool;
    fn get_admin(self: @T) -> starknet::ContractAddress;
    fn transfer_admin(ref self: T, new_admin: starknet::ContractAddress);
}

/// Immutable, append-only audit trail
#[starknet::interface]
pub trait IAuditTrail<T> {
    fn log_action(ref self: T, action: felt252, actor: starknet::ContractAddress);
    fn get_log_count(self: @T) -> u32;
}

// ===================================================================
// Access Control — proper (role, account) → bool mapping
// ===================================================================
#[starknet::contract]
pub mod AccessControl {
    use super::IAccessControl;
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };

    #[storage]
    struct Storage {
        admin: starknet::ContractAddress,
        roles: Map<(felt252, starknet::ContractAddress), bool>,
    }

    #[constructor]
    fn constructor(ref self: ContractState, admin: starknet::ContractAddress) {
        self.admin.write(admin);
        self.roles.write(('ADMIN', admin), true);
    }

    #[abi(embed_v0)]
    impl AccessControlImpl of IAccessControl<ContractState> {
        fn grant_role(ref self: ContractState, role: felt252, account: starknet::ContractAddress) {
            let caller = starknet::get_caller_address();
            assert(caller == self.admin.read(), 'Admin access required');
            self.roles.write((role, account), true);
        }

        fn revoke_role(
            ref self: ContractState, role: felt252, account: starknet::ContractAddress,
        ) {
            let caller = starknet::get_caller_address();
            assert(caller == self.admin.read(), 'Admin access required');
            self.roles.write((role, account), false);
        }

        fn has_role(
            self: @ContractState, role: felt252, account: starknet::ContractAddress,
        ) -> bool {
            self.roles.read((role, account))
        }

        fn get_admin(self: @ContractState) -> starknet::ContractAddress {
            self.admin.read()
        }

        fn transfer_admin(ref self: ContractState, new_admin: starknet::ContractAddress) {
            let caller = starknet::get_caller_address();
            assert(caller == self.admin.read(), 'Admin access required');
            let old_admin = self.admin.read();
            self.roles.write(('ADMIN', old_admin), false);
            self.roles.write(('ADMIN', new_admin), true);
            self.admin.write(new_admin);
        }
    }
}

// ===================================================================
// Audit Trail — append-only log with timestamps
// ===================================================================
#[starknet::contract]
pub mod AuditTrail {
    use super::IAuditTrail;
    use starknet::storage::{
        Map, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };

    #[storage]
    struct Storage {
        admin: starknet::ContractAddress,
        log_count: u32,
        log_actions: Map<u32, felt252>,
        log_actors: Map<u32, starknet::ContractAddress>,
        log_timestamps: Map<u32, u64>,
    }

    #[constructor]
    fn constructor(ref self: ContractState, admin: starknet::ContractAddress) {
        self.admin.write(admin);
        self.log_count.write(0);
    }

    #[abi(embed_v0)]
    impl AuditTrailImpl of IAuditTrail<ContractState> {
        fn log_action(
            ref self: ContractState, action: felt252, actor: starknet::ContractAddress,
        ) {
            let idx = self.log_count.read();
            self.log_actions.write(idx, action);
            self.log_actors.write(idx, actor);
            self.log_timestamps.write(idx, starknet::get_block_timestamp());
            self.log_count.write(idx + 1);
        }

        fn get_log_count(self: @ContractState) -> u32 {
            self.log_count.read()
        }
    }
}
