#!/usr/bin/env bash
set -uo pipefail
IFS=$'\n\t'

RED='\033[31m'; GRN='\033[32m'; YLW='\033[33m'; BLD='\033[1m'; RST='\033[0m'
if [[ "${PRE_COMMIT_COLOR:-}" == "never" ]]; then RED=''; GRN=''; YLW=''; BLD=''; RST=''; fi

exit_code=0

for f in "$@"; do
  dir="$(dirname "$f")"
  base="$(basename "$f")"

  echo -e "${BLD}→ ${f}${RST}"

  pushd "$dir" >/dev/null
  out="$(terraform fmt -check -diff -no-color "$base" 2>&1)"
  status=$?
  popd >/dev/null

  if [[ $status -eq 0 ]]; then
    echo -e "  ${GRN}✓ Formato correcto${RST}"
  else
    if grep -q "^Error:" <<<"$out"; then
      echo -e "  ${RED}✗ Error de sintaxis (terraform fmt)${RST}"
      echo "$out" | sed 's/^/    /'
    else
      echo -e "  ${RED}✗ No está formateado${RST} (aplicá 'terraform fmt')"
      echo "$out" | sed 's/^/    /'
    fi
    exit_code=1
  fi

  echo
done

exit "$exit_code"