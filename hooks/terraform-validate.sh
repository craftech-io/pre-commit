#!/usr/bin/env bash
set -uo pipefail
IFS=$'\n\t'

RED='\033[31m'; GRN='\033[32m'; YLW='\033[33m'; BLD='\033[1m'; RST='\033[0m'
if [[ "${PRE_COMMIT_COLOR:-}" == "never" ]]; then RED=''; GRN=''; YLW=''; BLD=''; RST=''; fi

VALIDATE_ARGS=()
[[ "${PRE_COMMIT_COLOR:-}" == "never" ]] && VALIDATE_ARGS+=("-no-color")

if [[ "$#" -gt 0 ]]; then
  mapfile -t DIRS < <(for f in "$@"; do dirname "$f"; done | sort -u)
else
  mapfile -t DIRS < <(git ls-files '*.tf' | xargs -n1 dirname | sort -u)
fi

exit_code=0

for d in "${DIRS[@]}"; do
  mapfile -t TFFILES < <(find "$d" -maxdepth 1 -type f -name '*.tf' | sort)
  [[ "${#TFFILES[@]}" -gt 0 ]] || continue

  echo -e "${BLD}>> Validando Terraform en: ${d}${RST}"
  pushd "${d}" >/dev/null

  set +e
  out_init="$(terraform init -backend=false -input=false 2>&1)"
  st_init=$?
  set -e

  if [[ $st_init -ne 0 ]]; then
    if grep -Eq "Error accessing remote module registry|401 Unauthorized|403 Forbidden|Failed to retrieve available versions" <<<"$out_init"; then
      echo -e "  ${YLW}! skipped${RST} (requires private registry auth)"
      echo "$out_init" | sed 's/^/    /'
      for f in "${TFFILES[@]}"; do
        echo -e "→ ${f}"
        echo -e "  ${YLW}! skipped${RST}"
      done
      popd >/dev/null
      echo
      continue
    fi

    echo -e "  ${RED}✗ init failed${RST}"
    echo "$out_init" | sed 's/^/    /'
    exit_code=1
    popd >/dev/null
    echo
    continue
  fi

  # ---------- VALIDATE ----------
  set +e
  out_val="$(terraform validate "${VALIDATE_ARGS[@]}" 2>&1)"
  st_val=$?
  set -e

  if [[ $st_val -eq 0 ]]; then
    for f in "${TFFILES[@]}"; do
      echo -e "→ ${f}"
      echo -e "  ${GRN}✓ Válido${RST}"
      echo
    done
  else
    echo -e "  ${RED}✗ validate failed${RST}"
    echo "$out_val" | sed 's/^/    /'
    exit_code=1
    echo
  fi

  popd >/dev/null
done

exit "$exit_code"