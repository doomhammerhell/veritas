// Time-Dilated module for Veritas
#[starknet::interface]
pub trait ITimeDilated<T> {
    fn create_time_vault(ref self: T, dilation_factor: u32, unlock_time: u64);
    fn deposit_to_vault(ref self: T, vault_id: u32, amount: u128);
    fn withdraw_from_vault(ref self: T, vault_id: u32);
    fn get_vault_balance(self: @T, vault_id: u32) -> u128;
    fn get_dilation_factor(self: @T, vault_id: u32) -> u32;
}

#[starknet::contract]
pub mod TimeDilated {
    use super::ITimeDilated;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        vaults: Map<u32, TimeVault>,
        next_vault_id: u32,
        admin: felt252,
        total_vaults: u32,
        base_time_rate: u32,
    }

    #[derive(Drop)]
    struct TimeVault {
        id: u32,
        owner: felt252,
        balance: u128,
        dilation_factor: u32,
        created_at: u64,
        unlock_time: u64,
        time_dilated_balance: u128,
        last_adjustment: u64,
    }

    #[constructor]
    fn constructor(ref self: ContractState, admin: felt252) {
        self.admin.write(admin);
        self.next_vault_id.write(1);
        self.total_vaults.write(0);
        self.base_time_rate.write(1000); // Base time rate
    }

    #[abi(embed_v0)]
    impl TimeDilatedImpl of ITimeDilated<ContractState> {
        fn create_time_vault(ref self: ContractState, dilation_factor: u32, unlock_time: u64) {
            let caller = starknet::get_caller_address();
            let vault_id = self.next_vault_id.read();
            
            let vault = TimeVault {
                id: vault_id,
                owner: caller,
                balance: 0,
                dilation_factor,
                created_at: starknet::get_block_timestamp(),
                unlock_time,
                time_dilated_balance: 0,
                last_adjustment: starknet::get_block_timestamp(),
            };
            
            self.vaults.write(vault_id, vault);
            self.next_vault_id.write(vault_id + 1);
            self.total_vaults.write(self.total_vaults.read() + 1);
        }

        fn deposit_to_vault(ref self: ContractState, vault_id: u32, amount: u128) {
            let caller = starknet::get_caller_address();
            let mut vault = self.vaults.read(vault_id);
            
            assert!(caller == vault.owner, "Not vault owner");
            assert!(amount > 0, "Amount must be positive");
            
            vault.balance = vault.balance + amount;
            
            // Apply time dilation
            let time_multiplier = (vault.dilation_factor * self.base_time_rate.read()) / 1000;
            vault.time_dilated_balance = vault.time_dilated_balance + (amount * time_multiplier.into());
            
            self.vaults.write(vault_id, vault);
        }

        fn withdraw_from_vault(ref self: ContractState, vault_id: u32) {
            let caller = starknet::get_caller_address();
            let mut vault = self.vaults.read(vault_id);
            
            assert!(caller == vault.owner, "Not vault owner");
            assert!(starknet::get_block_timestamp() >= vault.unlock_time, "Vault still locked");
            
            let withdraw_amount = vault.time_dilated_balance;
            vault.balance = 0;
            vault.time_dilated_balance = 0;
            
            self.vaults.write(vault_id, vault);
        }

        fn get_vault_balance(self: @ContractState, vault_id: u32) -> u128 {
            let vault = self.vaults.read(vault_id);
            vault.time_dilated_balance
        }

        fn get_dilation_factor(self: @ContractState, vault_id: u32) -> u32 {
            let vault = self.vaults.read(vault_id);
            vault.dilation_factor
        }
    }
}
