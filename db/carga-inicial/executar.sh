#!/bin/bash
# Ponto de entrada do serviço `carga` (docker compose --profile carga run --rm carga ...).
#
#   carga <nucleo|infraestrutura|noticias|todos> [diretorio]
#
# O diretório (padrão: $DADOS_DIR, ou seja ./dados no host) deve ter um
# subdiretório por conjunto com os CSVs do layout canônico (ver README.md).
# Cada conjunto roda numa única transação: qualquer rejeição desfaz tudo.
set -euo pipefail

CARGA_DIR="$(cd "$(dirname "$0")" && pwd)"
conjunto="${1:-}"
base="${2:-${DADOS_DIR:-/dados}}"

uso() {
  echo "uso: carga <nucleo|infraestrutura|noticias|todos> [diretorio]" >&2
  exit 2
}

carregar() {
  local c="$1" dir="$base/$1"
  [ -d "$dir" ] || { echo "diretório não encontrado: $dir" >&2; exit 1; }

  # Mapa arquivo -> SHA-256, gravado em nucleo.lote_carga
  local arquivos="{" sep=""
  for f in "$dir"/*.csv; do
    [ -e "$f" ] || continue
    arquivos+="$sep\"$(basename "$f")\": \"$(sha256sum "$f" | cut -d' ' -f1)\""
    sep=", "
  done
  arquivos+="}"

  echo "==> carga inicial: $c ($dir)"
  # \copy lê caminhos relativos ao diretório corrente
  (cd "$dir" && psql -X -q --single-transaction -v ON_ERROR_STOP=1 \
      -v arquivos="$arquivos" -f "$CARGA_DIR/$c/carga.sql")
  echo "==> $c: concluída"
}

case "$conjunto" in
  nucleo|infraestrutura|noticias) carregar "$conjunto" ;;
  todos) carregar nucleo; carregar infraestrutura; carregar noticias ;;
  *) uso ;;
esac
