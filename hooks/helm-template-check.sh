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
  echo -e "${BLD}>> Validando templates de Helm chart: ${chart_dir}${RST}"
  
  # Verificar que exista el directorio templates
  if [[ ! -d "$chart_dir/templates" ]]; then
    echo -e "  ${YLW}! Skipped (no hay directorio templates/)${RST}"
    echo
    continue
  fi
  
  pushd "$chart_dir" >/dev/null
  
  # Recolectar archivos de values para probar
  # 1. values.yaml (base)
  # 2. tests/values-*.yaml (casos de prueba)
  mapfile -t VALUES_FILES < <(
    [[ -f "values.yaml" ]] && echo "values.yaml"
    find tests -name "values-*.yaml" 2>/dev/null | sort
  )
  
  if [[ "${#VALUES_FILES[@]}" -eq 0 ]]; then
    echo -e "  ${YLW}! Skipped (no existe values.yaml)${RST}"
    popd >/dev/null
    echo
    continue
  fi
  
  # Probar con cada archivo de values
  chart_failed=0
  for values_file in "${VALUES_FILES[@]}"; do
    echo -e "  ${BLD}Testing with: ${values_file}${RST}"
    
    set +e
    # Ejecutar helm template y capturar output
    out="$(helm template test-release . --values "$values_file" 2>&1)"
    status=$?
    set -e
    
    if [[ $status -ne 0 ]]; then
      echo -e "    ${RED}✗ Error al renderizar templates${RST}"
      echo "$out" | sed 's/^/      /'
      chart_failed=1
      exit_code=1
    else
      # Validar que el YAML renderizado sea parseable
      set +e
      yaml_validation=$(echo "$out" | python3 -c "
import yaml
import sys
try:
    list(yaml.safe_load_all(sys.stdin))
    print('valid')
except yaml.YAMLError as e:
    print(f'YAML Error: {e}', file=sys.stderr)
    sys.exit(1)
" 2>&1)
      yaml_status=$?
      set -e
      
      if [[ $yaml_status -eq 0 ]]; then
        echo -e "    ${GRN}✓ Renderiza y genera YAML válido${RST}"
      else
        echo -e "    ${RED}✗ Genera YAML inválido${RST}"
        echo "$yaml_validation" | sed 's/^/      /'
        chart_failed=1
        exit_code=1
      fi
    fi
  done
  
  if [[ $chart_failed -eq 0 ]]; then
    echo -e "  ${GRN}✓ Todos los valores renderizan correctamente${RST}"
  fi
  
  popd >/dev/null
  echo
done

if [[ $exit_code -eq 0 ]]; then
  echo -e "${GRN}✓ Todos los templates se renderizaron correctamente${RST}"
else
  echo -e "${RED}✗ Algunos templates tienen errores${RST}"
fi

exit "$exit_code"
