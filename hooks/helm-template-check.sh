#!/usr/bin/env bash
set -uo pipefail
IFS=$'\n\t'

RED='\033[31m'; GRN='\033[32m'; YLW='\033[33m'; BLD='\033[1m'; RST='\033[0m'
if [[ "${PRE_COMMIT_COLOR:-}" == "never" ]]; then RED=''; GRN=''; YLW=''; BLD=''; RST=''; fi

# Verificar que helm y yamllint estén instalados
for cmd in helm yamllint; do
  if ! command -v "$cmd" &>/dev/null; then
    echo -e "${RED}✗ Error: ${cmd} no está instalado${RST}"
    exit 1
  fi
done

# Recolectar directorios únicos que contienen Chart.yaml
if [[ "$#" -gt 0 ]]; then
  mapfile -t CHART_DIRS < <(
    for f in "$@"; do
      dir="$(dirname "$f")"
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
  mapfile -t CHART_DIRS < <(find . -name "Chart.yaml" -exec dirname {} \; | sort -u)
fi

if [[ "${#CHART_DIRS[@]}" -eq 0 ]]; then
  echo -e "${YLW}! No se encontraron Helm charts (Chart.yaml)${RST}"
  exit 0
fi

exit_code=0
YAMLLINT_CONFIG_FILE=".yamllint"

for chart_dir in "${CHART_DIRS[@]}"; do
  echo -e "${BLD}>> Validando templates de Helm chart: ${chart_dir}${RST}"
  
  if [[ ! -d "$chart_dir/templates" ]]; then
    echo -e "  ${YLW}! Skipped (no hay directorio templates/)${RST}"
    echo
    continue
  fi
  
  pushd "$chart_dir" >/dev/null
  
  values_file="values.yaml"
  if [[ ! -f "$values_file" ]]; then
    echo -e "  ${YLW}! Skipped (no existe values.yaml)${RST}"
    popd >/dev/null
    echo
    continue
  fi
  
  set +e
  # Determinar la raíz del repo para resolver configuración de yamllint
  REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

  # Construir el comando de yamllint como un array (evita problemas con IFS sin espacios)
  yamllint_cmd=(yamllint)
  if [[ -f "$REPO_ROOT/.yamllint" ]]; then
    yamllint_cmd+=( -c "$REPO_ROOT/.yamllint" )
  elif [[ -f "$REPO_ROOT/.yamllint.yaml" ]]; then
    yamllint_cmd+=( -c "$REPO_ROOT/.yamllint.yaml" )
  else
    # Configuración relajada por defecto para evitar falsos positivos de estilo
    yamllint_cmd+=( -d '{extends: relaxed, rules: {line-length: disable, document-start: disable, trailing-spaces: enable, indentation: {spaces: consistent, indent-sequences: consistent}}}' )
  fi
  # Leer desde stdin
  yamllint_cmd+=( - )

  # Generar templates y validar YAML
  out="$(helm template test-release . --values "$values_file" | "${yamllint_cmd[@]}" 2>&1)"
  status=$?
  set -e
  
  if [[ $status -eq 0 ]]; then
    echo -e "  ${GRN}✓ Templates renderizan correctamente y el YAML es válido${RST}"
  else
    echo -e "  ${RED}✗ Error al renderizar o validar el YAML de los templates${RST}"
    echo "$out" | sed 's/^/    /'
    exit_code=1
  fi
  
  popd >/dev/null
  echo
done

if [[ $exit_code -eq 0 ]]; then
  echo -e "${GRN}✓ Todos los templates se renderizaron y validaron correctamente${RST}"
else
  echo -e "${RED}✗ Algunos templates tienen errores de renderizado o indentación${RST}"
fi

exit "$exit_code"