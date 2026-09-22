#!/usr/bin/env bash
# Gera docs/DICIONARIO-DADOS.md a partir de nucleo.v_dicionario_dados.
# Rode depois de cada migração para manter o documento em dia com o banco.
set -euo pipefail
export MSYS_NO_PATHCONV=1
cd "$(dirname "$0")/.."

docker compose exec -T db sh -c 'PGPASSWORD="$POSTGRES_PASSWORD" psql -X -At -U postgres -d invips' > docs/DICIONARIO-DADOS.md <<'SQL'
SELECT '# Dicionário de dados' || E'\n\n'
    || '> Gerado por `scripts/gerar-dicionario.sh` a partir de `nucleo.v_dicionario_dados`. '
    || 'Não edite à mão: altere os `COMMENT ON` nas migrações.' || E'\n';
SELECT string_agg(bloco, E'\n' ORDER BY esquema, tabela)
FROM (
  SELECT esquema, tabela,
         format(E'## %s.%s%s\n\n%s\n\n| Coluna | Tipo | Nulo | Descrição |\n|---|---|---|---|\n%s\n',
                esquema, tabela,
                CASE WHEN tipo_objeto = 'visão' THEN ' (visão)' ELSE '' END,
                descricao_tabela,
                string_agg(format('| `%s` | %s | %s | %s |', coluna, tipo,
                                  CASE WHEN aceita_nulo THEN 'sim' ELSE 'não' END,
                                  replace(descricao_coluna, '|', '\|')),
                           E'\n' ORDER BY posicao)) AS bloco
  FROM nucleo.v_dicionario_dados
  GROUP BY esquema, tabela, tipo_objeto, descricao_tabela
) t;
SQL
echo "docs/DICIONARIO-DADOS.md atualizado"
