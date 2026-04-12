# Contributing to Veritas

## Prerequisites

- [Scarb](https://docs.swmansion.com/scarb/) 2.16+
- [Starknet Foundry](https://github.com/foundry-rs/starknet-foundry) 0.57+
- Node.js 20+ (for frontend)

## Setup

```bash
git clone https://github.com/doomhammerhell/veritas.git
cd veritas
npm install        # installs husky + lint-staged
scarb build        # build Cairo contracts
snforge test       # run 39 tests
```

## Project Structure

```
src/
  veritas_main.cairo   — Main voting contract
  governance.cairo      — DAO proposals + emergency controls
  security.cairo        — Access control + audit trail
tests/
  test_contract.cairo  — Main contract tests (22)
  test_governance.cairo — Governance tests (10)
  test_security.cairo  — Security tests (7)
frontend/              — React app with starknet.js
docs/                  — VitePress documentation
scripts/               — Build, test, deploy scripts
```

## Workflow

1. Create a branch: `git checkout -b feat/your-feature`
2. Make changes
3. Format: `scarb fmt`
4. Test: `snforge test`
5. Commit using conventional commits: `feat:`, `fix:`, `docs:`, `test:`
6. Push and open a PR

## Cairo Style

- 4 spaces indentation
- snake_case for functions/variables
- PascalCase for types/structs
- Document public functions with `///` comments

## Git Hooks

- **pre-commit**: runs `scarb fmt` on staged `.cairo` files
- **pre-push**: runs `scarb build` + `snforge test`
