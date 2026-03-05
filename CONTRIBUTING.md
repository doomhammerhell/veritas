# Contributing to Veritas

Thank you for your interest in contributing to Veritas! This document provides guidelines and information for contributors.

## 🚀 Quick Start

### Prerequisites

- Node.js 20.x or higher
- Rust and Cairo 2.8.0 or higher
- Docker (optional, for containerized development)
- Git

### Setup Development Environment

1. **Fork and Clone**
   ```bash
   git clone https://github.com/your-username/veritas.git
   cd veritas
   ```

2. **Install Dependencies**
   ```bash
   npm install
   npm run prepare  # Sets up git hooks
   ```

3. **Setup Cairo Environment**
   ```bash
   # Install Cairo
   curl --proto '=https' --tlsv1.2 -sSf https://sw.kairo.network/cairo/install.sh | sh
   source ~/.bashrc
   ```

4. **Install Project Dependencies**
   ```bash
   scarb fetch
   ```

5. **Run Tests**
   ```bash
   npm run test:cairo
   npm run test:js
   ```

## 📁 Project Structure

```
veritas/
├── src/                     # Cairo source code
│   ├── core/               # Core modules
│   ├── voting/             # Voting modules
│   ├── governance/         # Governance modules
│   ├── security/           # Security modules
│   ├── analytics/          # Analytics modules
│   ├── optimization/       # Optimization modules
│   ├── interoperability/   # Interoperability modules
│   ├── ai/                 # AI modules
│   └── quantum/            # Quantum modules
├── frontend/               # React frontend
├── docs/                   # Documentation
├── scripts/                # Build and deployment scripts
├── tests/                  # Test files
├── monitoring/             # Monitoring configuration
└── target/                 # Build artifacts
```

## 🛠️ Development Workflow

### 1. Create a Feature Branch

```bash
git checkout -b feature/your-feature-name
```

### 2. Make Your Changes

- Follow the coding standards (see below)
- Write tests for your changes
- Update documentation if needed

### 3. Run Tests and Linting

```bash
# Run all tests
npm run test:cairo
npm run test:js

# Run linting
npm run lint:cairo
npm run lint:js

# Fix formatting
npm run format:cairo
npm run format:js
```

### 4. Commit Your Changes

We use [Conventional Commits](https://www.conventionalcommits.org/) specification:

```bash
# Feature
git commit -m "feat: add new voting mechanism"

# Bug fix
git commit -m "fix: resolve memory leak in analytics module"

# Documentation
git commit -m "docs: update API documentation"

# Style
git commit -m "style: format cairo files according to standards"

# Refactor
git commit -m "refactor: optimize gas usage in voting contracts"

# Test
git commit -m "test: add integration tests for governance module"

# Chore
git commit -m "chore: update dependencies"
```

### 5. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then create a pull request following our [PR template](.github/PULL_REQUEST_TEMPLATE.md).

## 📝 Coding Standards

### Cairo Code Style

- Use 4 spaces for indentation
- Maximum line length: 100 characters
- Use snake_case for variables and functions
- Use PascalCase for types and structs
- Add documentation comments for public functions

```cairo
/// Calculates the quadratic voting weight for a given voter
/// # Arguments
/// * `voter` - The address of the voter
/// * `vote_amount` - The amount of voting tokens
/// # Returns
/// The calculated quadratic weight
fn calculate_quadratic_weight(voter: ContractAddress, vote_amount: u256) -> u256 {
    // Implementation here
}
```

### JavaScript/TypeScript Code Style

- Use 2 spaces for indentation
- Maximum line length: 100 characters
- Use camelCase for variables and functions
- Use PascalCase for classes and types
- Add JSDoc comments for public functions

```typescript
/**
 * Calculates the quadratic voting weight for a given voter
 * @param voter - The address of the voter
 * @param voteAmount - The amount of voting tokens
 * @returns The calculated quadratic weight
 */
export function calculateQuadraticWeight(
  voter: string,
  voteAmount: bigint
): bigint {
  // Implementation here
}
```

## 🧪 Testing

### Cairo Tests

```bash
# Run all tests
scarb test

# Run specific test
scarb test test_name

# Run tests with filter
scarb test --filter voting
```

### JavaScript Tests

```bash
# Run all tests
npm run test:js

# Run tests with coverage
npm run test:coverage

# Run specific test file
npm test -- voting.test.ts
```

### Test Structure

```cairo
#[cfg(test)]
mod tests {
    use super::*;
    use starknet::testing::set_contract_address;

    #[test]
    fn test_voting_mechanism() {
        // Test implementation
    }
}
```

```typescript
describe('Voting Mechanism', () => {
  it('should calculate quadratic weight correctly', () => {
    // Test implementation
  });
});
```

## 📚 Documentation

### Code Documentation

- Add JSDoc comments for all public functions
- Include parameter descriptions and return types
- Add examples for complex functions

### API Documentation

- Update API documentation in `docs/api/`
- Include request/response examples
- Document error codes and handling

### README Updates

- Update README.md for new features
- Update CHANGELOG.md for breaking changes
- Update installation instructions if needed

## 🔒 Security

### Security Guidelines

- Follow our [Security Policy](SECURITY.md)
- Report security vulnerabilities privately
- Use secure coding practices
- Review code for common vulnerabilities

### Security Checklist

- [ ] Input validation implemented
- [ ] Access controls in place
- [ ] Error handling doesn't leak information
- [ ] Cryptographic functions used correctly
- [ ] No hardcoded secrets

## 🚀 Release Process

### Versioning

We follow [Semantic Versioning](https://semver.org/):
- MAJOR: Breaking changes
- MINOR: New features (backward compatible)
- PATCH: Bug fixes (backward compatible)

### Release Steps

1. Update version in package.json and Scarb.toml
2. Update CHANGELOG.md
3. Create release tag
4. Automated release process will handle the rest

## 🤝 Community

### Getting Help

- Create an issue for bugs or feature requests
- Join our Discord community
- Check existing documentation

### Code Review Process

1. All PRs require at least one review
2. Automated tests must pass
3. Code must follow style guidelines
4. Documentation must be updated

### Maintainer Responsibilities

- Review and merge PRs
- Handle security issues
- Manage releases
- Support the community

## 📋 Development Tools

### Recommended VS Code Extensions

- Cairo Language Server
- ESLint
- Prettier
- GitLens
- Docker
- GitHub Copilot

### Git Hooks

We use Husky for git hooks:
- Pre-commit: Linting and formatting
- Pre-push: Running tests

### CI/CD

Our CI/CD pipeline includes:
- Automated testing
- Code quality checks
- Security scanning
- Documentation deployment
- Docker image building

## 🌟 Recognition

Contributors are recognized in:
- README.md contributors section
- Release notes
- Annual contributor awards

## 📄 License

By contributing to Veritas, you agree that your contributions will be licensed under the MIT License.

## 🙏 Thank You

Thank you for contributing to Veritas! Your contributions help make decentralized governance more secure and accessible.

---

## 📞 Contact

- Email: dev@veritas.io
- Discord: [Veritas Community](https://discord.gg/veritas)
- Twitter: [@VeritasProtocol](https://twitter.com/VeritasProtocol)
