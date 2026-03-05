// Core module for Veritas - Complete Implementation
#[starknet::interface]
pub trait IVeritasCore<T> {
    fn initialize(ref self: T, admin: felt252);
    fn is_initialized(self: @T) -> bool;
    fn get_admin(self: @T) -> felt252;
    fn set_admin(ref self: T, new_admin: felt252);
    fn get_contract_info(self: @T) -> Array<felt252>;
}

#[starknet::interface]
pub trait IStorage<T> {
    fn store_data(ref self: T, key: felt252, value: felt252);
    fn get_data(self: @T, key: felt252) -> felt252;
    fn get_all_keys(self: @T) -> Array<felt252>;
    fn clear_storage(ref self: T);
}

#[starknet::contract]
pub mod VeritasStorage {
    use super::IVeritasCore;
    use super::IStorage;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        admin: felt252,
        initialized: bool,
        data: Map<felt252, felt252>,
        keys: Array<felt252>,
        created_at: u64,
        last_updated: u64,
    }

    #[constructor]
    fn constructor(ref self: ContractState, admin: felt252) {
        self.admin.write(admin);
        self.initialized.write(true);
        self.created_at.write(starknet::get_block_timestamp());
        self.last_updated.write(starknet::get_block_timestamp());
    }

    #[abi(embed_v0)]
    impl VeritasStorageImpl of IVeritasCore<ContractState> {
        fn initialize(ref self: ContractState, admin: felt252) {
            let caller = starknet::get_caller_address();
            let current_admin = self.admin.read();
            assert!(caller.into() == current_admin, "Only admin can initialize");
            assert!(!self.initialized.read(), "Already initialized");
            
            self.initialized.write(true);
            self.last_updated.write(starknet::get_block_timestamp());
        }

        fn is_initialized(self: @ContractState) -> bool {
            self.initialized.read()
        }

        fn get_admin(self: @ContractState) -> felt252 {
            self.admin.read()
        }

        fn set_admin(ref self: ContractState, new_admin: felt252) {
            let caller = starknet::get_caller_address();
            let current_admin = self.admin.read();
            assert!(caller.into() == current_admin, "Only admin can change admin");
            
            self.admin.write(new_admin);
            self.last_updated.write(starknet::get_block_timestamp());
        }

        fn get_contract_info(self: @ContractState) -> Array<felt252> {
            array![
                self.admin.read(),
                self.initialized.read().into(),
                self.created_at.read().into(),
                self.last_updated.read().into(),
                self.keys.read().len().into()
            ]
        }
    }

    #[abi(embed_v0)]
    impl StorageImpl of IStorage<ContractState> {
        fn store_data(ref self: ContractState, key: felt252, value: felt252) {
            let caller = starknet::get_caller_address();
            let admin = self.admin.read();
            assert!(caller.into() == admin, "Only admin can store data");
            
            self.data.write(key, value);
            
            // Add key to keys array if not already present
            let mut found = false;
            let keys = self.keys.read();
            let mut i = 0;
            while i < keys.len() {
                if *keys.at(i) == key {
                    found = true;
                    break;
                }
                i += 1;
            }
            
            if !found {
                let mut new_keys = keys;
                new_keys.append(key);
                self.keys.write(new_keys);
            }
            
            self.last_updated.write(starknet::get_block_timestamp());
        }

        fn get_data(self: @ContractState, key: felt252) -> felt252 {
            self.data.read(key)
        }

        fn get_all_keys(self: @ContractState) -> Array<felt252> {
            self.keys.read()
        }

        fn clear_storage(ref self: ContractState) {
            let caller = starknet::get_caller_address();
            let admin = self.admin.read();
            assert!(caller.into() == admin, "Only admin can clear storage");
            
            self.keys.write(array![]);
            self.last_updated.write(starknet::get_block_timestamp());
        }
    }
}

// Re-export core components
pub use VeritasStorage;
