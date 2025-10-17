#!/usr/bin/env bash
set -uo pipefail
IFS=$'\n\t'

RED='\033[31m'; GRN='\033[32m'; YLW='\033[33m'; BLD='\033[1m'; RST='\033[0m'
if [[ "${PRE_COMMIT_COLOR:-}" == "never" ]]; then RED=''; GRN=''; YLW=''; BLD=''; RST=''; fi

# Verificar que yamllint esté instalado
if ! command -v yamllint &>/dev/null; then
  echo -e "${RED}✗ Error: yamllint no está instalado${RST}"
  echo "  Instalá yamllint:"
  echo "    - macOS: brew install yamllint"
  echo "    - Linux: pip install yamllint (o pipx install yamllint)"
  exit 1
fi

exit_code=0

# Si no hay archivos, salir
if [[ "$#" -eq 0 ]]; then
  echo -e "${YLW}! No hay archivos YAML para validar${RST}"
  exit 0
fi

for f in "$@"; do
  echo -e "${BLD}→ ${f}${RST}"
  
  set +e
  out="$(yamllint -f parsable "$f" 2>&1)"
  status=$?
  set -e
  
  if [[ $status -eq 0 ]]; then
    echo -e "  ${GRN}✓ YAML válido${RST}"
  else
    echo -e "  ${RED}✗ Errores de sintaxis YAML${RST}"
    # Formatear output para mejor legibilidad
    echo "$out" | sed 's/^/    /'
    exit_code=1
  fi
  
  echo
done

exit "$exit_code"
