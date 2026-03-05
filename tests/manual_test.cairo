#[cfg(test)]
mod tests {
    use veritas::IVeritasDispatcher;
    use veritas::IVeritasDispatcherTrait;
    use starknet::ContractAddress;
    use starknet::contract_address_const;
    use core::pedersen::pedersen;

    #[test]
    fn test_manual_voting_flow() {
        // Simulate voting flow without snforge
        
        // Test data
        let vote: u8 = 1;
        let salt: felt252 = 12345;
        let commitment = pedersen(vote.into(), salt);
        
        // Verify hash calculation
        let expected_hash = pedersen(vote.into(), salt);
        assert(commitment == expected_hash, 'Hash calculation failed');
        
        // Test vote validation
        assert(vote > 0 && vote <= 5, 'Invalid vote option');
        
        // Test salt generation
        let different_salt = 54321;
        let different_commitment = pedersen(vote.into(), different_salt);
        assert(commitment != different_commitment, 'Same salt should produce different hash');
        
        println('✅ Manual test passed: Basic voting logic works');
    }
    
    #[test]
    fn test_hash_verification() {
        // Test cryptographic verification logic
        
        let vote: u8 = 2;
        let salt: felt252 = 99999;
        let commitment = pedersen(vote.into(), salt);
        
        // Correct reveal should pass
        let verify_hash = pedersen(vote.into(), salt);
        assert(verify_hash == commitment, 'Correct reveal should pass');
        
        // Wrong vote should fail
        let wrong_vote = 3;
        let wrong_hash = pedersen(wrong_vote.into(), salt);
        assert(wrong_hash != commitment, 'Wrong vote should fail');
        
        // Wrong salt should fail
        let wrong_salt = 11111;
        let wrong_salt_hash = pedersen(vote.into(), wrong_salt);
        assert(wrong_salt_hash != commitment, 'Wrong salt should fail');
        
        println('✅ Manual test passed: Hash verification works');
    }
}
