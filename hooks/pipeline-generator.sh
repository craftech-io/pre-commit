#!/bin/bash

# Run pre-commits-hooks
# Install these tools.
# brew install pre-commit gawk terraform-docs tflint tfsec coreutils checkov terrascan

set -e 

# Load variables defined in .pgen-env
if [ -z ".pgen-env" ]; then echo "Create and define vars in .pgen-env fiel." && exit 1; fi
. .pgen-env

# Check if variables are loaded.
if [ -z "$PGEN_EXTRA_KNOW_HOST" ]; then echo "set \$PGEN_EXTRA_KNOW_HOST variable." && exit 1; fi
if [ -z "$PGEN_IMAGE" ]; then echo "set \$PGEN_IMAGE variable." && exit 1; fi
if [ -z "$PGEN_PROVIDER" ]; then echo "set \$PGEN_PROVIDER variable." && exit 1; fi
if [ -z "$PGEN_OUTPUT_FILE" ]; then echo "set \$PGEN_OUTPUT_FILE variable." && exit 1; fi

# Install pipeline generator.
if ! command -v pipeline-generator &> /dev/null
then
    echo "installing pipeline-generator"
    pip install -U git+ssh://git@github.com/craftech-io/module-ci.git@feature/gitlab-ci-helper#subdirectory=modules/gitlab-ci-helpers/pipeline-generator
fi

# Clean cache.
find . -type d -name ".terragrunt-cache" -prune -exec rm -rf {} \;

pipeline-generator -i $PGEN_IMAGE -e $PGEN_EXTRA_KNOW_HOST -o $PGEN_OUTPUT_FILE -p $PGEN_PROVIDER

# Add to commit.
git add .
