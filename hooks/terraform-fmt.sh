#!/bin/bash

set -e

for file in "$@"; do
  pushd "$(dirname "$file")" >/dev/null
  terraform fmt -write=true "$(basename "$file")"
  popd >/dev/null
done