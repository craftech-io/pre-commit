#!/bin/sh

# Run pre-commits-hooks
# Install these tools.
# brew install pre-commit gawk terraform-docs tflint tfsec coreutils checkov terrascan

# Install pipeline generator.
pip3 install git+ssh://git@github.com/craftech-io/module-ci.git@feature/gitlab-ci-helper#subdirectory=modules/gitlab-ci-helpers/pipeline-generator

# Clean cache.
find . -type d -name ".terragrunt-cache" -prune -exec rm -rf {} \;

# Generate gitlab-ci.yml
pipeline-generator -i "craftech/ci-tools:iac-tools-latest" -e $EXTRA_KNOW_HOST -o .gitlab-ci.yml

# Add to commit.
git add .gitlab-ci.yml