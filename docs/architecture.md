# Architecture

## Contracts

Veritas consists of 3 independent StarkNet contracts:

```
src/
  veritas_main.cairo   — Main voting contract (commit-reveal + admin)
  governance.cairo      — DAO proposals + emergency controls
  security.cairo        — Role-based access control + audit trail
```

### Veritas (main)

The core voting contract. Implements a two-phase commit-reveal scheme with Pedersen hash.

**State machine:**

```
[Deploy] → Commit Phase → Reveal Phase → Ended
               ↕                ↕
            [Paused]         [Paused]
```

**Storage:**

| Field | Type | Description |
|-------|------|-------------|
| admin | felt252 | Admin address for emergency controls |
| paused | bool | Emergency pause flag |
| num_options | u8 | Number of valid vote options |
| commit_end | u64 | Timestamp: end of commit phase |
| reveal_end | u64 | Timestamp: end of reveal phase |
| commitments | Map\<address, felt252\> | Voter → Pedersen commitment |
| has_committed | Map\<address, bool\> | Voter → committed flag |
| has_revealed | Map\<address, bool\> | Voter → revealed flag |
| tally | Map\<u8, u32\> | Vote option → count |

### DAOGovernance

Standalone proposal system with quorum enforcement and execution delay.

### AccessControl

Role-based access control with `(role, account) → bool` mapping.

### AuditTrail

Append-only log with action, actor, and timestamp per entry.

## Invariants

| # | Name | How enforced |
|---|------|-------------|
| INV-1 | Uniqueness | `has_committed` + `has_revealed` booleans |
| INV-2 | Binding | `pedersen(vote, salt) == stored_commitment` |
| INV-3 | Consistency | `has_committed` required before reveal |
| INV-4 | Temporality | `commit_end` and `reveal_end` timestamps |
| INV-5 | Finality | `reveal_end` closes voting; admin can pause |
| INV-6 | Validity | `vote < num_options` checked on reveal |

## Frontend

React app using `starknet.js` for wallet connection, Pedersen hash computation, and transaction submission. Salt is stored in `localStorage` between commit and reveal phases.
