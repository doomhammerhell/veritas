---
layout: home

hero:
  name: Veritas
  text: Commit-reveal blind voting on StarkNet
  tagline: Secure, private, and verifiable decentralized governance
  actions:
    - theme: brand
      text: Quick Start
      link: /guide/quick-start
    - theme: alt
      text: GitHub
      link: https://github.com/doomhammerhell/veritas

features:
  - icon: 🔒
    title: Commit-Reveal Privacy
    details: Votes are hidden during the voting period using Pedersen hash commitments. Only revealed after the deadline.
  - icon: ⏱️
    title: Temporal Enforcement
    details: Separate commit and reveal phases with on-chain deadlines. No late commits, no late reveals.
  - icon: 🛡️
    title: Admin Emergency Controls
    details: Admin can pause/unpause the contract in case of discovered exploits, with full event audit trail.
  - icon: ✅
    title: 39 Tests, 6 Invariants
    details: Every security property is formally defined and tested — uniqueness, binding, consistency, temporality, finality, validity.
---
