# Pre-commit hooks

This repo defines Git pre-commit hooks intended for use with [pre-commit](https://pre-commit.com/). The currently
supported hooks are:

> 🚀 **Quick Start**: New to pre-commit? Check out our [Quick Start Guide](QUICKSTART.md) for a 5-minute setup!

## Terraform Hooks

* **terraform-fmt**: Checks that all Terraform files (`*.tf`) are properly formatted (`terraform fmt --check -diff`).
* **terraform-validate**: Runs `terraform init -backend=false` and then `terraform validate`.  
  > Notes: directories requiring a private registry and lacking credentials are marked as **skipped** (do not fail the commit). Both hooks ignore `.terraform/` and `examples/`.

## Helm/Kubernetes Hooks

* **helm-lint**: Executes `helm lint` on all Helm charts (directories with `Chart.yaml`). Validates chart structure, syntax, and best practices.
* **helm-template-check**: Runs `helm template` to ensure templates can render without errors. Uses the default `values.yaml` file. Does not validate the output against Kubernetes schemas.
* **yamllint**: Validates YAML syntax and style for all `.yaml` and `.yml` files. Checks indentation, duplicates, trailing spaces, etc.
  > Note: Copy `.yamllint.yaml` to your repo root for custom configuration.

## General Usage

In each of your repos, add a file called `.pre-commit-config.yaml` with the following contents:

### For Terraform projects:

```yaml
repos:
  - repo: git@github.com:craftech-io/pre-commit.git   # or https://github.com/craftech-io/pre-commit.git
    rev: <VERSION>
    hooks:
      - id: terraform-fmt
      - id: terraform-validate
        verbose: true
```

### For Helm/Kubernetes projects:

```yaml
repos:
  - repo: git@github.com:craftech-io/pre-commit.git   # or https://github.com/craftech-io/pre-commit.git
    rev: <VERSION>
    hooks:
      - id: yamllint
      - id: helm-lint
      - id: helm-template-check
```

### For mixed projects (Terraform + Helm):

```yaml
repos:
  - repo: git@github.com:craftech-io/pre-commit.git
    rev: <VERSION>
    hooks:
      # Terraform
      - id: terraform-fmt
      - id: terraform-validate
      # Helm/Kubernetes
      - id: yamllint
      - id: helm-lint
      - id: helm-template-check
```

Next, have every developer:

1. Install [pre-commit](https://pre-commit.com/#install).  
   - macOS: `brew install pre-commit`  
   - Linux: `pipx install pre-commit` (or `pip install --user pre-commit`)
2. Install required tools based on your hooks:
   - **Terraform hooks**: Install [Terraform](https://www.terraform.io/downloads)
   - **Helm hooks**: Install [Helm](https://helm.sh/docs/intro/install/)
   - **yamllint hook**: Install yamllint (`brew install yamllint` or `pip install yamllint`)
3. Run `pre-commit install` in the repo.

That's it! Now every time you commit a code change (`.tf` file), the hooks in the `hooks:` config will execute.  
If any hook fails, the commit is aborted; if all pass, the commit succeeds.

## Running Against All Files At Once

### Terraform: Formatting and validating all files

If you'd like to run the hooks across the whole repo (useful the first time), you can run:

```bash
# Check formatting for all Terraform files
pre-commit run terraform-fmt --all-files

# Validate all Terraform directories
pre-commit run terraform-validate --all-files
```

### Helm/Kubernetes: Linting and validating all files

```bash
# Validate YAML syntax in all files
pre-commit run yamllint --all-files

# Lint all Helm charts
pre-commit run helm-lint --all-files

# Check that all Helm templates can render
pre-commit run helm-template-check --all-files
```

### Run all configured hooks at once

```bash
# Or run every configured hook across the repo
pre-commit run --all-files
```

> Tip: for detailed output on demand, use `-v`, e.g. `pre-commit run -v helm-lint --all-files`.

## Optional Configuration

### yamllint Configuration

By default, `yamllint` uses strict rules. You can customize the behavior by copying the example configuration to your repo:

```bash
# Copy the example configuration
cp .yamllint.yaml /path/to/your/repo/.yamllint.yaml

# Or download it directly
curl -O https://raw.githubusercontent.com/craftech-io/pre-commit/main/.yamllint.yaml
```

Then customize `.yamllint.yaml` in your repo root according to your needs. See [yamllint documentation](https://yamllint.readthedocs.io/) for all available options.

## Troubleshooting

### Helm hooks are skipped

If the Helm hooks show "No Helm charts found", ensure your repository has:
- A `Chart.yaml` file in your chart directory
- A `templates/` directory with your Kubernetes manifests
- A `values.yaml` file (required for template rendering)

### yamllint is too strict

If yamllint reports too many warnings for your use case:
1. Copy the `.yamllint.yaml` configuration file to your repo
2. Adjust the rules (e.g., increase `line-length`, disable specific rules)
3. Commit the configuration file

### Dependencies not installed

Each hook requires specific tools to be installed:
- **terraform-fmt, terraform-validate**: Requires Terraform CLI
- **helm-lint, helm-template-check**: Requires Helm CLI
- **yamllint**: Requires yamllint Python package

Install missing tools before running `pre-commit install`.

## License

This code is released under the Apache 2.0 License. Please see [LICENSE](LICENSE) for more details.