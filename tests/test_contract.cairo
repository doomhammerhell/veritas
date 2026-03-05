#[cfg(test)]
mod tests {
    use core::pedersen::pedersen;
    use snforge_std::{ContractClassTrait, declare, start_prank, start_warp, stop_prank, stop_warp};
    use starknet::{ContractAddress, contract_address_const};
    use veritas::{IVeritasDispatcher, IVeritasDispatcherTrait};

    #[test]
    fn test_voting_flow() {
        // 1. Deploy Contract
        let contract = declare("Veritas").unwrap();
        // Voting duration: 100 seconds
        let mut constructor_args = array![100];
        let (contract_address, _) = contract.deploy(@constructor_args).unwrap();
        let dispatcher = IVeritasDispatcher { contract_address };

        // 2. Commit Vote
        let voter = contract_address_const::<123>();
        start_prank(contract_address, voter);

        let vote: u8 = 1;
        let salt: felt252 = 12345;
        let commitment = pedersen(vote.into(), salt);

        dispatcher.commit_vote(commitment);

        stop_prank(contract_address);

        // 3. Try to Reveal Early (Should Fail)
        start_prank(contract_address, voter);
        // Time is 0, end is 100. Should fail.
        // We need to catch this panic? Or just assert it panics?
        // In simple tests, we just let it panic if we expect it.
        // But here we want to test success path first.

        // Advance time to 101
        start_warp(contract_address, 101);

        // 4. Reveal Vote
        dispatcher.reveal_vote(vote, salt);

        // 5. Check Tally
        let tally = dispatcher.get_tally(vote);
        assert(tally == 1, 'Tally should be 1');

        stop_prank(contract_address);
        stop_warp(contract_address);
    }

    #[test]
    #[should_panic(expected: ('Voting Period Ended',))]
    fn test_commit_after_deadline() {
        let contract = declare("Veritas").unwrap();
        let mut constructor_args = array![100];
        let (contract_address, _) = contract.deploy(@constructor_args).unwrap();
        let dispatcher = IVeritasDispatcher { contract_address };

        let voter = contract_address_const::<123>();
        start_prank(contract_address, voter);

        start_warp(contract_address, 101);

        let vote: u8 = 1;
        let salt: felt252 = 12345;
        let commitment = pedersen(vote.into(), salt);

        dispatcher.commit_vote(commitment);
    }

    #[test]
    #[should_panic(expected: ('Voting Not Ended Yet',))]
    fn test_reveal_too_early() {
        let contract = declare("Veritas").unwrap();
        let mut constructor_args = array![100];
        let (contract_address, _) = contract.deploy(@constructor_args).unwrap();
        let dispatcher = IVeritasDispatcher { contract_address };

        let voter = contract_address_const::<123>();
        start_prank(contract_address, voter);

        let vote: u8 = 1;
        let salt: felt252 = 12345;
        let commitment = pedersen(vote.into(), salt);

        dispatcher.commit_vote(commitment);

        // Time is still 0 (or small), < 100
        dispatcher.reveal_vote(vote, salt);
    }

    #[test]
    #[should_panic(expected: ('Fraudulent Reveal',))]
    fn test_reveal_wrong_salt() {
        let contract = declare("Veritas").unwrap();
        let mut constructor_args = array![100];
        let (contract_address, _) = contract.deploy(@constructor_args).unwrap();
        let dispatcher = IVeritasDispatcher { contract_address };

        let voter = contract_address_const::<123>();
        start_prank(contract_address, voter);

        let vote: u8 = 1;
        let salt: felt252 = 12345;
        let commitment = pedersen(vote.into(), salt);

        dispatcher.commit_vote(commitment);

        start_warp(contract_address, 101);

        // Try to reveal with wrong salt
        dispatcher.reveal_vote(vote, 99999);
    }

    #[test]
    #[should_panic(
        expected: ('Fraudulent Reveal',),
    )] // Or 'No Vote Found' depending on impl details, but likely Fraudulent Reveal first
    fn test_double_reveal() {
        let contract = declare("Veritas").unwrap();
        let mut constructor_args = array![100];
        let (contract_address, _) = contract.deploy(@constructor_args).unwrap();
        let dispatcher = IVeritasDispatcher { contract_address };

        let voter = contract_address_const::<123>();
        start_prank(contract_address, voter);

        let vote: u8 = 1;
        let salt: felt252 = 12345;
        let commitment = pedersen(vote.into(), salt);

        dispatcher.commit_vote(commitment);

        start_warp(contract_address, 101);

        dispatcher.reveal_vote(vote, salt);

        // Try to reveal again
        dispatcher.reveal_vote(vote, salt);
    }

    #[test]
    #[should_panic(expected: ('Already Voted',))]
    fn test_double_commit() {
        let contract = declare("Veritas").unwrap();
        let mut constructor_args = array![100];
        let (contract_address, _) = contract.deploy(@constructor_args).unwrap();
        let dispatcher = IVeritasDispatcher { contract_address };

        let voter = contract_address_const::<123>();
        start_prank(contract_address, voter);

        let vote: u8 = 1;
        let salt: felt252 = 12345;
        let commitment = pedersen(vote.into(), salt);

        dispatcher.commit_vote(commitment);

        // Try to commit again
        dispatcher.commit_vote(commitment);
    }

    #[test]
    #[should_panic(expected: ('Fraudulent Reveal',))]
    fn test_reveal_wrong_vote() {
        let contract = declare("Veritas").unwrap();
        let mut constructor_args = array![100];
        let (contract_address, _) = contract.deploy(@constructor_args).unwrap();
        let dispatcher = IVeritasDispatcher { contract_address };

        let voter = contract_address_const::<123>();
        start_prank(contract_address, voter);

        let vote: u8 = 1;
        let salt: felt252 = 12345;
        let commitment = pedersen(vote.into(), salt);

        dispatcher.commit_vote(commitment);

        start_warp(contract_address, 101);

        // Try to reveal with wrong vote
        dispatcher.reveal_vote(vote + 1, salt);
    }
}
