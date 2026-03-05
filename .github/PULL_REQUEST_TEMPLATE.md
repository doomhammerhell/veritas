name: Pull Request Template
description: Template for pull requests
body:
  - type: markdown
    attributes:
      value: |
        # Pull Request Guidelines

        Thank you for contributing to Veritas! Please ensure your PR follows our guidelines.

  - type: checkboxes
    id: pr-checklist
    attributes:
      label: PR Checklist
      description: Please ensure you've completed the following
      options:
        - label: I have read the [Contributing Guidelines](https://github.com/veritas-org/veritas/blob/main/CONTRIBUTING.md)
          required: true
        - label: I have read the [Code of Conduct](https://github.com/veritas-org/veritas/blob/main/CODE_OF_CONDUCT.md)
          required: true
        - label: My code follows the style guidelines of this project
          required: true
        - label: I have performed a self-review of my code
          required: true
        - label: I have commented my code, particularly in hard-to-understand areas
          required: true
        - label: My changes generate no new warnings
          required: true
        - label: I have added tests that prove my fix is effective or that my feature works
          required: true
        - label: New and existing unit tests pass locally with my changes
          required: true
        - label: Any dependent changes have been merged and published in downstream modules
          required: true

  - type: textarea
    id: description
    attributes:
      label: Description
      description: Brief description of your changes
      placeholder: Describe your changes here...
    validations:
      required: true

  - type: textarea
    id: motivation
    attributes:
      label: Motivation and Context
      description: Why is this change needed? What problem does it solve?
      placeholder: Explain the motivation behind this change...

  - type: textarea
    id: testing
    attributes:
      label: How Has This Been Tested?
      description: Please describe in detail how you tested your changes
      placeholder: |
        - [ ] Unit tests pass
        - [ ] Integration tests pass
        - [ ] Manual testing completed
        - [ ] Security review completed

  - type: textarea
    id: breaking-changes
    attributes:
      label: Breaking Changes
      description: Are there any breaking changes?
      placeholder: |
        - [ ] No breaking changes
        - [ ] Breaking changes: describe them here...

  - type: textarea
    id: screenshots
    attributes:
      label: Screenshots (if applicable)
      description: Add screenshots to help explain your changes
      placeholder: Add screenshots here...

  - type: textarea
    id: checklist
    attributes:
      label: Additional Notes
      description: Any additional notes or context
      placeholder: Add any additional notes here...

  - type: dropdown
    id: type
    attributes:
      label: Type of Change
      description: What type of change is this?
      options:
        - Bug fix (non-breaking change that fixes an issue)
        - New feature (non-breaking change that adds functionality)
        - Breaking change (fix or feature that would cause existing functionality to not work as expected)
        - Documentation update
        - Performance improvement
        - Security fix
        - Refactoring (no functional changes)
        - Other
    validations:
      required: true

  - type: dropdown
    id: component
    attributes:
      label: Component
      description: Which component does this change affect?
      options:
        - Cairo Contracts
        - Frontend
        - Documentation
        - CI/CD
        - Security
        - Infrastructure
        - Other
    validations:
      required: true

  - type: checkboxes
    id: release-notes
    attributes:
      label: Release Notes
      description: Please check if this should be included in release notes
      options:
        - label: Include in release notes
          required: false

  - type: markdown
    attributes:
      value: |
        ## Review Process

        1. Automated checks will run on this PR
        2. At least one maintainer must review and approve
        3. All conversations must be resolved
        4. PR must be up-to-date with main branch
        5. CI/CD pipeline must pass

        Thank you for your contribution! 🚀
