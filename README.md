# Pre-commit Hooks Collection

<div align="center">

**Quality gates for your Infrastructure as Code**

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://pre-commit.com/)

</div>

---

## Overview

This repository provides a curated collection of **Git pre-commit hooks** designed to enforce best practices and catch issues early in your Infrastructure as Code (IaC) workflows. By integrating these hooks into your development process, you can ensure code quality, consistency, and compliance before changes ever reach your repository.

### Why Use Pre-commit Hooks?

- **Catch issues early** - Identify problems before they reach CI/CD
- **Fast feedback loop** - Get instant validation on your local machine
- **Enforce standards** - Maintain consistent code quality across teams
- **Prevent broken commits** - Block commits that don't meet your criteria
- **Team collaboration** - Share the same quality gates with everyone

---

## Available Hooks

### Terraform Hooks

| Hook | Description | What it does |
|------|-------------|--------------|
| `terraform-fmt` | **Format checker** | Verifies all `.tf` files are properly formatted using `terraform fmt --check -diff` |
| `terraform-validate` | **Syntax validator** | Runs `terraform init -backend=false` followed by `terraform validate` to catch configuration errors |

> **Note:** Directories requiring private registries without credentials are automatically skipped. Both hooks ignore `.terraform/` and `examples/` directories.

### Helm Hooks

| Hook | Description | What it does |
|------|-------------|--------------|
| `helm-lint` | **Chart linter** | Validates Helm charts using `helm lint` to check for common issues and best practices |
| `helm-template-check` | **Template validator** | Renders templates with `helm template` to ensure they generate valid Kubernetes manifests |

> **Note:** Helm hooks automatically discover charts by locating `Chart.yaml` files in your repository.

---

## Quick Start

### Prerequisites

First, ensure you have [pre-commit](https://pre-commit.com/) installed on your system:

```bash
# macOS
brew install pre-commit

# Linux (recommended)
pipx install pre-commit

# Linux (alternative)
pip install --user pre-commit

# Windows (WSL or Git Bash)
pip install pre-commit
```

### Installation

**Step 1: Add the configuration file**

Create a `.pre-commit-config.yaml` file in the root of your repository:

```yaml
repos:
  - repo: git@github.com:craftech-io/pre-commit.git
    # or use: https://github.com/craftech-io/pre-commit.git
    rev: <VERSION>  # Use the latest release tag
    hooks:
      # Terraform hooks
      - id: terraform-fmt
      - id: terraform-validate
        verbose: true  # Show detailed output
      
      # Helm hooks
      - id: helm-lint
      - id: helm-template-check
```

> **Tip:** Replace `<VERSION>` with the latest release tag (e.g., `v1.0.0`). Check the [releases page](https://github.com/craftech-io/pre-commit/releases) for available versions.

**Step 2: Install the hooks**

Run this command in your repository:

```bash
pre-commit install
```

**Step 3: You're all set!**

Now, every time you run `git commit`, the configured hooks will automatically execute. If any hook fails, the commit will be blocked, allowing you to fix issues before they're committed.

---

## Usage

### Automatic Validation (Recommended)

Once installed, hooks run automatically on every commit:

```bash
git add .
git commit -m "feat: add new infrastructure"
# Hooks will run automatically here!
```

### Manual Execution

Run hooks manually without committing:

```bash
# Run all configured hooks on staged files
pre-commit run

# Run a specific hook on staged files
pre-commit run terraform-fmt

# Run hooks on all files in the repository
pre-commit run --all-files

# Run a specific hook on all files
pre-commit run terraform-validate --all-files
```

### Common Commands

```bash
# Run all hooks with verbose output
pre-commit run --all-files -v

# Run only Terraform hooks
pre-commit run terraform-fmt --all-files
pre-commit run terraform-validate --all-files

# Run only Helm hooks
pre-commit run helm-lint --all-files
pre-commit run helm-template-check --all-files

# Update hooks to the latest version
pre-commit autoupdate

# Temporarily bypass hooks (not recommended!)
git commit --no-verify
```

---

## Advanced Configuration

### Customizing Hook Behavior

You can customize hooks in your `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: git@github.com:craftech-io/pre-commit.git
    rev: <VERSION>
    hooks:
      - id: terraform-fmt
        # Run on specific file patterns only
        files: ^modules/
        
      - id: terraform-validate
        # Exclude specific directories
        exclude: ^(examples|tests)/
        
      - id: helm-lint
        # Always show verbose output
        verbose: true
        
      - id: helm-template-check
        # Run even if files haven't changed
        always_run: false
```

### Combining with Other Hooks

Mix these hooks with other pre-commit hooks for comprehensive validation:

```yaml
repos:
  # This repository's hooks
  - repo: git@github.com:craftech-io/pre-commit.git
    rev: <VERSION>
    hooks:
      - id: terraform-fmt
      - id: helm-lint
  
  # Additional hooks from other sources
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
```

---

## Contributing

We welcome contributions! Here's how you can help improve this project:

### Adding New Hooks

1. **Create the hook script** in the `hooks/` directory
2. **Make it executable**: `chmod +x hooks/your-hook.sh`
3. **Add entry** to `.pre-commit-hooks.yaml`
4. **Test thoroughly** with various scenarios
5. **Submit a pull request** with a clear description

### Testing Your Changes

Before submitting a PR, test your hooks:

```bash
# Test on a specific file
bash hooks/your-hook.sh path/to/test/file

# Test with pre-commit
pre-commit try-repo /path/to/your/local/repo your-hook-id --verbose --all-files
```

### Development Guidelines

- Follow existing code style and structure
- Include error handling and clear error messages
- Add colorized output for better readability
- Write descriptive commit messages
- Update documentation (README, comments)
- Test on multiple scenarios (success, failure, edge cases)

### Reporting Issues

Found a bug or have a suggestion? Please [open an issue](https://github.com/craftech-io/pre-commit/issues) with:

- **Clear description** of the problem or enhancement
- **Steps to reproduce** (for bugs)
- **Expected vs actual behavior**
- **Environment details** (OS, tool versions)

---

## Additional Resources

- [Pre-commit Documentation](https://pre-commit.com/)
- [Terraform Documentation](https://www.terraform.io/docs)
- [Helm Documentation](https://helm.sh/docs/)
- [Pre-commit Hook Examples](https://github.com/pre-commit/pre-commit-hooks)

---

## License

This project is released under the **Apache 2.0 License**.


<div align="center">

**[Back to Top](#pre-commit-hooks-collection)**

Made by Craftech

</div>