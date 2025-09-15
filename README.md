# Pre-commit hooks

This repo defines Git pre-commit hooks intended for use with [pre-commit](https://pre-commit.com/). The currently
supported hooks are:

* **terraform-fmt**: Checks that all Terraform files (`*.tf`) are properly formatted (`terraform fmt --check -diff`).
* **terraform-validate**: Runs `terraform init -backend=false` and then `terraform validate`.  
  > Notes: directories requiring a private registry and lacking credentials are marked as **skipped** (do not fail the commit). Both hooks ignore `.terraform/` and `examples/`.

## General Usage

In each of your repos, add a file called `.pre-commit-config.yaml` with the following contents:

```yaml
repos:
  - repo: git@github.com:craftech-io/pre-commit.git   # or https://github.com/craftech-io/pre-commit.git
    rev: <VERSION>
    hooks:
      - id: terraform-fmt
      - id: terraform-validate
        verbose: true
```

Next, have every developer:

1. Install [pre-commit](https://pre-commit.com/#install).  
   - macOS: `brew install pre-commit`  
   - Linux: `pipx install pre-commit` (or `pip install --user pre-commit`)
2. Run `pre-commit install` in the repo.

That's it! Now every time you commit a code change (`.tf` file), the hooks in the `hooks:` config will execute.  
If any hook fails, the commit is aborted; if all pass, the commit succeeds.

## Running Against All Files At Once

### Example: Formatting and validating all files

If you'd like to run the hooks across the whole repo (useful the first time), you can run:

```bash
# Check formatting for all Terraform files
pre-commit run terraform-fmt --all-files

# Validate all Terraform directories
pre-commit run terraform-validate --all-files

# Or run every configured hook across the repo
pre-commit run --all-files
```

> Tip: for detailed output on demand, use `-v`, e.g. `pre-commit run -v terraform-validate --all-files`.

## License

This code is released under the Apache 2.0 License. Please see [LICENSE](LICENSE) for more details.