#!/usr/bin/env bash
set -uo pipefail
IFS=$'\n\t'

RED='\033[31m'; GRN='\033[32m'; YLW='\033[33m'; BLD='\033[1m'; RST='\033[0m'
if [[ "${PRE_COMMIT_COLOR:-}" == "never" ]]; then RED=''; GRN=''; YLW=''; BLD=''; RST=''; fi

# Verificar que helm esté instalado
if ! command -v helm &>/dev/null; then
  echo -e "${RED}✗ Error: helm no está instalado${RST}"
  echo "  Instalá helm desde: https://helm.sh/docs/intro/install/"
  exit 1
fi

# Recolectar directorios únicos que contienen Chart.yaml
if [[ "$#" -gt 0 ]]; then
  # Buscar Chart.yaml en los directorios de los archivos modificados
  mapfile -t CHART_DIRS < <(
    for f in "$@"; do
      dir="$(dirname "$f")"
      # Buscar hacia arriba hasta encontrar Chart.yaml
      while [[ "$dir" != "." && "$dir" != "/" ]]; do
        if [[ -f "$dir/Chart.yaml" ]]; then
          echo "$dir"
          break
        fi
        dir="$(dirname "$dir")"
      done
    done | sort -u
  )
else
  # Buscar todos los Chart.yaml en el repo
  mapfile -t CHART_DIRS < <(find . -name "Chart.yaml" -exec dirname {} \; | sort -u)
fi

# Si no hay charts, salir exitosamente
if [[ "${#CHART_DIRS[@]}" -eq 0 ]]; then
  echo -e "${YLW}! No se encontraron Helm charts (Chart.yaml)${RST}"
  exit 0
fi

exit_code=0

for chart_dir in "${CHART_DIRS[@]}"; do
  echo -e "${BLD}>> Validando Helm chart: ${chart_dir}${RST}"
  
  pushd "$chart_dir" >/dev/null
  
  set +e
  out="$(helm lint . 2>&1)"
  status=$?
  set -e
  
  if [[ $status -eq 0 ]]; then
    echo -e "  ${GRN}✓ Chart válido${RST}"
    # Mostrar warnings si existen pero el lint pasó
    if grep -q "WARNING" <<<"$out"; then
      echo -e "  ${YLW}⚠ Warnings encontrados:${RST}"
      echo "$out" | grep "WARNING" | sed 's/^/    /'
    fi
  else
    echo -e "  ${RED}✗ Lint falló${RST}"
    echo "$out" | sed 's/^/    /'
    exit_code=1
  fi
  
  popd >/dev/null
  echo
done

if [[ $exit_code -eq 0 ]]; then
  echo -e "${GRN}✓ Todos los charts pasaron helm lint${RST}"
else
  echo -e "${RED}✗ Algunos charts tienen errores de lint${RST}"
fi

exit "$exit_code"
