#!/bin/sh

# Run pre-commits-hooks
# Install these tools.
# brew install pre-commit gawk terraform-docs tflint tfsec coreutils checkov terrascan

set -e 

# Install pipeline generator.
if ! command -v pipeline-generator &> /dev/null
then
    echo "installing pipeline-generator"
    pip install -U git+ssh://git@github.com/craftech-io/module-ci.git@feature/gitlab-ci-helper#subdirectory=modules/gitlab-ci-helpers/pipeline-generator
fi

# Clean cache.
find . -type d -name ".terragrunt-cache" -prune -exec rm -rf {} \;

# Generate gitlab-ci.yml
if [ -z "$EXTRA_KNOW_HOST" ]; then echo "set \$EXTRA_KNOW_HOST variable." && exit 1; fi
pipeline-generator -i "craftech/ci-tools:iac-tools-latest" -e $EXTRA_KNOW_HOST -o .gitlab-ci.yml -p gitlab

# Add to commit.
git add .gitlab-ci.yml
