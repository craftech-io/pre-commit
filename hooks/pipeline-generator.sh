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
if [ -z "$PGEN_BRANCH" ]; then echo "set \$PGEN_BRANCH variable." && exit 1; fi
if [ -z "$PGEN_OUTPUT_FILE" ]; then echo "set \$PGEN_OUTPUT_FILE variable." && exit 1; fi
if [ -z "$PGEN_ENABLE_VAULT_ENVS" ]; then echo "set \$PGEN_ENABLE_VAULT_ENVS variable." && exit 1; fi
if [ -z "$PGEN_VAULT_ROLE" ]; then echo "set \$PGEN_VAULT_ROLE variable." && exit 1; fi
if [ -z "$PGEN_VAULT_BASE_PATH " ]; then echo "set \$PGEN_VAULT_BASE_PATH variable." && exit 1; fi
if [ -z "$PGEN_VAULT_AUTH_METHOD" ]; then echo "set \$PGEN_VAULT_AUTH_METHOD." && exit 1; fi

# Install pipeline generator.
if ! command -v pipeline-generator &> /dev/null
then
    echo "installing pipeline-generator"
    pip install -U git+https://git@github.com/craftech-io/pipeline-generator.git@v0.8.4
fi

# Clean cache.
find . -type d -name ".terragrunt-cache" -prune -exec rm -rf {} \;

if [ "$PGEN_ENABLE_VAULT_ENVS" == "true" ]; then
  pipeline-generator -i $PGEN_IMAGE -e $PGEN_EXTRA_KNOW_HOST -o $PGEN_OUTPUT_FILE -b $PGEN_BRANCH --enable-vault-envs --vault-role=$PGEN_VAULT_ROLE --vault-base-path=$PGEN_VAULT_BASE_PATH --vault-auth-method=$PGEN_VAULT_AUTH_METHOD
else
 pipeline-generator -i $PGEN_IMAGE -e $PGEN_EXTRA_KNOW_HOST -o $PGEN_OUTPUT_FILE -b $PGEN_BRANCH
fi

# Add to commit.
git add .
