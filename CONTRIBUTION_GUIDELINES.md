### Custos-Starknet Smart Contract Contributor Guidelines

Thank you for your interest in contributing to the Custos-Starknet project! This repository contains the smart contracts for Custos, written in Cairo using Scarb. We appreciate contributions of all types, whether it’s a bug fix, new feature, or improvement to our documentation. Please follow the guidelines below to ensure a smooth contribution process.

## Table of Contents
1. [Code of Conduct](#code-of-conduct)
2. [How to Contribute](#how-to-contribute)
3. [Development Environment Setup](#development-environment-setup)
4. [Project Setup](#project-setup)
5. [Testing Guidelines](#testing-guidelines)
6. [Branching and Commit Guidelines](#branching-and-commit-guidelines)
7. [Pull Requests](#pull-requests)
8. [Workflow Examples](#workflow-examples)
9. [Coding Standards](#coding-standards)
10. [Issue Reporting](#issue-reporting)
11. [Resources](#resources)
12. [License](#license)

---

## 1. Code of Conduct

Please adhere to our [Code of Conduct](#). We expect all contributors to maintain professionalism and respect when engaging with the community.

---

## 2. How to Contribute

There are several ways to contribute to Custos-Starknet:

- **Report Bugs**: Open an issue to report bugs.
- **Suggest Features**: Open an issue to suggest new features.
- **Fix Bugs or Implement Features**: Check open issues and submit a pull request with your contributions.
- **Improve Documentation**: Enhancing documentation is always welcome.

---

## 3. Development Environment Setup

### Prerequisites

i. Rust Installation(required for Scarb)

   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   source $HOME/.cargo/env
   ```

ii. [Scarb Installation](https://docs.swmansion.com/scarb/download.html)
- For [macOS/Linux](https://docs.swmansion.com/scarb/download.html#install-via-installation-script):
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh
   ```
- For [Windows](https://docs.swmansion.com/scarb/download.html#windows):

   - Download the installer from [Scarb releases](https://docs.swmansion.com/scarb/download.html#precompiled-packages)
   - Add Scarb to your system PATH


### Development Tools
1. VS Code Extensions(recommended)
- Cairo Language Support
- Scarb Build Tools
- Better TOML

---


## 4. Project Setup

To contribute, you need to set up the project locally:

1. Fork the repository.
2. Clone your fork:
   ```bash
   git clone https://github.com/your-username/custos-starknet.git
   ```
3. Navigate to the project directory:
   ```bash
   cd custos-starknet
   ```
4. Install Scarb if you haven't already: [Scarb Installation Guide](https://docs.swmansion.com/scarb/docs/getting_started/installation).
5. Install Project Dependencies:
   ```bash
   scarb build
   ```
6. Run tests:
   ```bash
   scarb test
   ```
7. Make sure everything works before making changes.

---

## 5. Testing Guidelines
### Running Tests

   ```bash
   scarb test
   ```

### Writing Tests
   ```cairo
   #[test]
   fn test_something() {
      // Arrange
      // Act
      // Assert
   }
   ```

### Test Naming Convention
   - Use descriptive names. 
   - Example: `test_deposit_with_valid_amount_succeeds`

---

## 6. Branching and Commit Guidelines

- **Branch Naming**: 
  - `feature/your-feature-name` for new features.
  - `bugfix/issue-number-description` for bug fixes.

- **Commit Messages**:
  - Use clear, concise messages that describe what the commit does.
  - Example:
    ```bash
    feat: add new collateralization feature for loan contracts
    ```

---

## 7. Pull Requests

- Ensure your branch is up to date with the main branch.
- Push your changes and open a PR against `master`.
- Provide a detailed description of your changes.
- Link any relevant issues.

---

## 8. Workflow Examples

### Adding a New Feature

1. Create feature branch:
   ```bash
   git checkout -b feature/<new-feature-name>
   ```
2. Implement feature and tests:
   ```bash
   # Write your code 
   # Add tests
   scarb test
   ```
   
3. Submit PR:
   ```bash
   git add .
   git commit -m "feat: add new feature description"
   git push origin feature/<new-feature-name>
   ```

### Fixing a Bug

1. Create bug fix branch:
   ```bash
   git checkout -b bugfix/issue-number-description
2. Fix and Verify:
   ```bash
   # Fix the bug
   # Add/modify test
   scarb test
   ```
3. Submit PR:
   ```bash
   git add .
   git commit -m "fix: resolve issue description"
   git push origin bugfix/issue-number-description
   ```

---

## 9. Coding Standards

- **Cairo Code**: Follow the [Cairo documentation](https://www.cairo-lang.org/docs/) and best practices.
- **Testing**: Write tests for your code and ensure all tests pass before submitting a PR.

---

## 10. Issue Reporting

When reporting issues:

- Use descriptive titles.
- Provide as much detail as possible.
- Include relevant environment information.

---

## 11. Resources

- [Cairo Documentation](https://www.cairo-lang.org/docs/)
- [Scarb Documentation](https://docs.swmansion.com/scarb/)
