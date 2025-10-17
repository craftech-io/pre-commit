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
  
  set +e
  # Ejecutar helm template y capturar el output
  rendered_output="$(helm template test-release . --values "$values_file" 2>&1)"
  status=$?
  set -e
  
  if [[ $status -ne 0 ]]; then
    echo -e "  ${RED}✗ Error al renderizar templates${RST}"
    echo "$rendered_output" | sed 's/^/    /'
    exit_code=1
  else
    # Templates renderizaron bien, ahora validar el YAML resultante
    echo -e "  ${GRN}✓ Templates renderizan correctamente${RST}"
    
    # Validar YAML solo si yamllint está disponible
    if command -v yamllint &>/dev/null; then
      echo -e "  ${BLD}→ Validando sintaxis YAML del output...${RST}"
      
      set +e
      yaml_errors="$(echo "$rendered_output" | yamllint -f parsable -d '{extends: default, rules: {line-length: disable, document-start: disable}}' - 2>&1)"
      yaml_status=$?
      set -e
      
      if [[ $yaml_status -eq 0 ]]; then
        echo -e "  ${GRN}✓ YAML del output es válido${RST}"
      else
        echo -e "  ${RED}✗ YAML del output tiene errores de sintaxis/indentación${RST}"
        echo "$yaml_errors" | sed 's/^/    /'
        exit_code=1
      fi
    else
      echo -e "  ${YLW}⚠ yamllint no está instalado, no se validó la sintaxis del YAML renderizado${RST}"
      echo -e "    Instalá yamllint para validación completa:"
      echo -e "      - macOS: brew install yamllint"
      echo -e "      - Linux: pip install yamllint (o pipx install yamllint)"
    fi
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