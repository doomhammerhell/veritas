// Veritas contract ABI — generated from veritas_main.cairo IVeritas trait
// Update this after recompilation if the interface changes.
export const VERITAS_ABI = [
  {
    type: "impl",
    name: "VeritasImpl",
    interface_name: "veritas::veritas_main::IVeritas",
  },
  {
    type: "interface",
    name: "veritas::veritas_main::IVeritas",
    items: [
      {
        type: "function",
        name: "commit_vote",
        inputs: [{ name: "commitment", type: "core::felt252" }],
        outputs: [],
        state_mutability: "external",
      },
      {
        type: "function",
        name: "reveal_vote",
        inputs: [
          { name: "vote", type: "core::integer::u8" },
          { name: "salt", type: "core::felt252" },
        ],
        outputs: [],
        state_mutability: "external",
      },
      {
        type: "function",
        name: "emergency_pause",
        inputs: [],
        outputs: [],
        state_mutability: "external",
      },
      {
        type: "function",
        name: "emergency_unpause",
        inputs: [],
        outputs: [],
        state_mutability: "external",
      },
      {
        type: "function",
        name: "transfer_admin",
        inputs: [{ name: "new_admin", type: "core::felt252" }],
        outputs: [],
        state_mutability: "external",
      },
      {
        type: "function",
        name: "get_tally",
        inputs: [{ name: "vote", type: "core::integer::u8" }],
        outputs: [{ type: "core::integer::u32" }],
        state_mutability: "view",
      },
      {
        type: "function",
        name: "get_total_commits",
        inputs: [],
        outputs: [{ type: "core::integer::u32" }],
        state_mutability: "view",
      },
      {
        type: "function",
        name: "get_total_reveals",
        inputs: [],
        outputs: [{ type: "core::integer::u32" }],
        state_mutability: "view",
      },
      {
        type: "function",
        name: "get_num_options",
        inputs: [],
        outputs: [{ type: "core::integer::u8" }],
        state_mutability: "view",
      },
      {
        type: "function",
        name: "get_commit_end",
        inputs: [],
        outputs: [{ type: "core::integer::u64" }],
        state_mutability: "view",
      },
      {
        type: "function",
        name: "get_reveal_end",
        inputs: [],
        outputs: [{ type: "core::integer::u64" }],
        state_mutability: "view",
      },
      {
        type: "function",
        name: "is_paused",
        inputs: [],
        outputs: [{ type: "core::bool" }],
        state_mutability: "view",
      },
      {
        type: "function",
        name: "get_admin",
        inputs: [],
        outputs: [{ type: "core::felt252" }],
        state_mutability: "view",
      },
      {
        type: "function",
        name: "get_phase",
        inputs: [],
        outputs: [{ type: "core::integer::u8" }],
        state_mutability: "view",
      },
    ],
  },
  {
    type: "constructor",
    name: "constructor",
    inputs: [
      { name: "admin", type: "core::felt252" },
      { name: "num_options", type: "core::integer::u8" },
      { name: "commit_dur", type: "core::integer::u64" },
      { name: "reveal_dur", type: "core::integer::u64" },
    ],
  },
  {
    type: "event",
    name: "veritas::veritas_main::Veritas::Event",
    kind: "enum",
    variants: [
      {
        name: "VoteCommitted",
        type: "veritas::veritas_main::Veritas::VoteCommitted",
        kind: "nested",
      },
      {
        name: "VoteRevealed",
        type: "veritas::veritas_main::Veritas::VoteRevealed",
        kind: "nested",
      },
      {
        name: "EmergencyPaused",
        type: "veritas::veritas_main::Veritas::EmergencyPaused",
        kind: "nested",
      },
      {
        name: "EmergencyUnpaused",
        type: "veritas::veritas_main::Veritas::EmergencyUnpaused",
        kind: "nested",
      },
      {
        name: "AdminTransferred",
        type: "veritas::veritas_main::Veritas::AdminTransferred",
        kind: "nested",
      },
    ],
  },
];
