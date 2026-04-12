# Veritas

Secure commit-reveal blind voting on StarkNet.

## What it does

Veritas is a voting protocol where votes are hidden during the voting period and only revealed after it ends. This prevents strategic voting, front-running, and vote manipulation.

The protocol uses a two-phase commit-reveal scheme with Pedersen hash for cryptographic binding.

## How it works

1. **Commit phase** — Voters submit `pedersen(vote, salt)` as a commitment. The vote stays secret.
2. **Reveal phase** — After the commit deadline, voters reveal their `(vote, salt)`. The contract verifies the hash matches.
3. **Finality** — After the reveal deadline, no more state changes. Results are final.

## Invariants

| # | Property | Enforcement |
|---|----------|-------------|
| INV-1 | One vote per address | `has_committed` + `has_revealed` booleans |
| INV-2 | Cryptographic binding | `pedersen(vote, salt) == stored_commitment` |
| INV-3 | Reveals ≤ commits | `has_committed` required before reveal |
| INV-4 | Temporal phases | `commit_end` and `reveal_end` timestamps |
| INV-5 | Finality + emergency | `reveal_end` closes voting; admin can pause |
| INV-6 | Vote validity | `vote < num_options` checked on reveal |

## Project structure

```
src/
  lib.cairo              — crate root, re-exports
  veritas_main.cairo     — main voting contract (commit-reveal + admin)
  governance.cairo        — DAO proposals + emergency controls
  security.cairo          — access control + audit trail
tests/
  test_contract.cairo    — 22 tests for the main contract
  test_governance.cairo  — 10 tests for governance
  test_security.cairo    — 7 tests for security
  manual_test.cairo      — Pedersen hash property tests
```

## Build

```bash
scarb build
```

## Test

```bash
snforge test
```

Requires [Starknet Foundry](https://github.com/foundry-rs/starknet-foundry).

## Constructor parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `admin` | `felt252` | Admin address for emergency pause/unpause |
| `num_options` | `u8` | Number of valid vote options (≥ 2) |
| `commit_dur` | `u64` | Commit phase duration in seconds |
| `reveal_dur` | `u64` | Reveal phase duration in seconds |

## Contract interface

```cairo
trait IVeritas<T> {
    // Voter
    fn commit_vote(ref self: T, commitment: felt252);
    fn reveal_vote(ref self: T, vote: u8, salt: felt252);

    // Admin
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

## License

MIT
