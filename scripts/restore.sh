#!/usr/bin/env bash
# Restauração (RF-10).
#
#   scripts/restore.sh <arquivo.dump> [banco_destino]
#
# Por padrão restaura num banco separado (invips_restauracao) e compara a
# contagem de linhas de cada tabela com o banco invips: é o teste periódico
# de restauração. Para restaurar por cima do próprio invips (recuperação de
# desastre), use banco_destino=invips com CONFIRMAR=sim.
set -euo pipefail
export MSYS_NO_PATHCONV=1
cd "$(dirname "$0")/.."

arquivo="$(basename "${1:?uso: scripts/restore.sh <arquivo.dump> [banco_destino]}")"
destino="${2:-invips_restauracao}"

[ -f "backups/$arquivo" ] || { echo "não encontrado: backups/$arquivo" >&2; exit 1; }
if [ "$destino" = "invips" ] && [ "${CONFIRMAR:-}" != "sim" ]; then
  echo "restaurar sobre o banco invips apaga o conteúdo atual; rode com CONFIRMAR=sim" >&2
  exit 1
fi

inicio=$(date +%s)
docker compose exec -T -e ARQ="$arquivo" -e DEST="$destino" db sh -euc '
  cd /backups
  sha256sum -c "$ARQ.sha256"
  export PGPASSWORD="$POSTGRES_PASSWORD"
  if [ "$DEST" = "invips" ]; then
    psql -X -q -U postgres -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '"'"'invips'"'"' AND pid <> pg_backend_pid()" >/dev/null
  fi
  dropdb -U postgres --if-exists "$DEST"
  createdb -U postgres -O invips_admin "$DEST"
  pg_restore -U postgres -d "$DEST" --exit-on-error "/backups/$ARQ"
'
fim=$(date +%s)
echo "restaurado em $destino em $((fim - inicio)) s"

[ "$destino" = "invips" ] && exit 0

# Compara contagens por tabela entre invips e o banco restaurado
contar='SELECT table_schema || '"'"'.'"'"' || table_name,
  (xpath('"'"'/row/c/text()'"'"', query_to_xml(format('"'"'SELECT count(*) AS c FROM %I.%I'"'"', table_schema, table_name), false, true, '"'"''"'"')))[1]::text
FROM information_schema.tables
WHERE table_schema IN ('"'"'nucleo'"'"', '"'"'infraestrutura'"'"', '"'"'noticias'"'"', '"'"'auditoria'"'"') AND table_type = '"'"'BASE TABLE'"'"'
ORDER BY 1'

origem="$(docker compose exec -T -e Q="$contar" db sh -c 'PGPASSWORD="$POSTGRES_PASSWORD" psql -X -At -U postgres -d invips -c "$Q"')"
restaurado="$(docker compose exec -T -e Q="$contar" -e DEST="$destino" db sh -c 'PGPASSWORD="$POSTGRES_PASSWORD" psql -X -At -U postgres -d "$DEST" -c "$Q"')"

if [ "$origem" = "$restaurado" ]; then
  echo "contagens idênticas em $(echo "$origem" | wc -l) tabelas"
else
  echo "DIVERGÊNCIA nas contagens (invips x $destino):" >&2
  diff <(echo "$origem") <(echo "$restaurado") >&2 || true
  exit 1
fi
