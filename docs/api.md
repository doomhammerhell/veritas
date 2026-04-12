# API Reference

## IVeritas — Main Contract

```cairo
trait IVeritas<T> {
    // Voter actions
    fn commit_vote(ref self: T, commitment: felt252);
    fn reveal_vote(ref self: T, vote: u8, salt: felt252);

    // Admin actions
    fn emergency_pause(ref self: T);
    fn emergency_unpause(ref self: T);
    fn transfer_admin(ref self: T, new_admin: felt252);

    // View
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
```

### Constructor

| Parameter | Type | Description |
|-----------|------|-------------|
| admin | felt252 | Admin address |
| num_options | u8 | Number of vote options (≥ 2) |
| commit_dur | u64 | Commit phase duration (seconds) |
| reveal_dur | u64 | Reveal phase duration (seconds) |

### commit_vote

Submit `pedersen(vote, salt)` during commit phase. Reverts if paused, after deadline, or already committed.

### reveal_vote

Reveal `(vote, salt)` during reveal phase. Verifies Pedersen hash matches stored commitment. Reverts if wrong hash, wrong phase, invalid option, or already revealed.

### Events

| Event | Fields | When |
|-------|--------|------|
| VoteCommitted | voter (key) | After successful commit |
| VoteRevealed | voter (key), vote | After successful reveal |
| EmergencyPaused | admin, timestamp | Admin pauses |
| EmergencyUnpaused | admin, timestamp | Admin unpauses |
| AdminTransferred | old_admin, new_admin | Admin transfer |

## IDAOGovernance

```cairo
trait IDAOGovernance<T> {
    fn create_proposal(ref self: T, title: felt252, description: felt252);
    fn vote_on_proposal(ref self: T, proposal_id: u32, support: bool);
    fn execute_proposal(ref self: T, proposal_id: u32);
    fn get_proposal_votes(self: @T, proposal_id: u32) -> (u32, u32);
    fn get_proposal_count(self: @T) -> u32;
    fn is_proposal_executed(self: @T, proposal_id: u32) -> bool;
}
```

## IAccessControl

```cairo
trait IAccessControl<T> {
    fn grant_role(ref self: T, role: felt252, account: ContractAddress);
    fn revoke_role(ref self: T, role: felt252, account: ContractAddress);
    fn has_role(self: @T, role: felt252, account: ContractAddress) -> bool;
    fn get_admin(self: @T) -> ContractAddress;
    fn transfer_admin(ref self: T, new_admin: ContractAddress);
}
```

## IAuditTrail

```cairo
trait IAuditTrail<T> {
    fn log_action(ref self: T, action: felt252, actor: ContractAddress);
    fn get_log_count(self: @T) -> u32;
}
```
