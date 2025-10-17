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
  
  # Verificar si existe values.yaml
  values_file="values.yaml"
  if [[ ! -f "$values_file" ]]; then
    echo -e "  ${YLW}! Skipped (no existe values.yaml)${RST}"
    popd >/dev/null
    echo
    continue
  fi
  
  # Array para almacenar archivos de valores a probar
  declare -a values_files=("$values_file")
  
  # Buscar archivos de ejemplo en examples/
  if [[ -d "examples" ]]; then
    while IFS= read -r -d '' example_file; do
      values_files+=("$example_file")
    done < <(find examples -type f \( -name "*.yaml" -o -name "*.yml" \) -print0 2>/dev/null | sort -z)
  fi
  
  echo -e "  ${BLD}Casos de prueba encontrados: ${#values_files[@]}${RST}"
  
  # Iterar sobre todos los archivos de valores
  for values_test_file in "${values_files[@]}"; do
    # Obtener nombre descriptivo del archivo
    if [[ "$values_test_file" == "values.yaml" ]]; then
      test_name="valores por defecto"
    else
      test_name="$(basename "$values_test_file")"
    fi
    
    echo -e "  ${BLD}→ Probando: ${test_name}${RST}"
    
    set +e
    # Ejecutar helm template solo para verificar que renderice sin errores
    # No validamos el output, solo que pueda generar algo
    out="$(helm template test-release . --values "$values_test_file" 2>&1 >/dev/null)"
    status=$?
    set -e
    
    if [[ $status -eq 0 ]]; then
      echo -e "    ${GRN}✓ Templates renderizan correctamente${RST}"
    else
      echo -e "    ${RED}✗ Error al renderizar templates${RST}"
      echo "$out" | sed 's/^/      /'
      exit_code=1
    fi
  done
  
  popd >/dev/null
  echo
done

if [[ $exit_code -eq 0 ]]; then
  echo -e "${GRN}✓ Todos los templates se renderizaron correctamente con todos los casos de prueba${RST}"
else
  echo -e "${RED}✗ Algunos templates tienen errores en uno o más casos de prueba${RST}"
fi

exit "$exit_code"