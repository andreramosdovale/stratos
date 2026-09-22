#!/usr/bin/env bash
# Cria um usuário nominal, só leitura, para um pesquisador (herda invips_leitor).
# A senha é gerada e mostrada uma única vez.
#
#   scripts/criar-pesquisador.sh <usuario>
set -euo pipefail
export MSYS_NO_PATHCONV=1
cd "$(dirname "$0")/.."

usuario="${1:?uso: scripts/criar-pesquisador.sh <usuario>}"
[[ "$usuario" =~ ^[a-z][a-z0-9_]{2,40}$ ]] || { echo "usuário deve ser minúsculo, [a-z0-9_]" >&2; exit 1; }

docker compose exec -T -e USUARIO="$usuario" db sh -euc '
  senha="$(head -c 24 /dev/urandom | base64 | tr -d "/+=" | head -c 24)"
  PGPASSWORD="$POSTGRES_PASSWORD" psql -X -q -v ON_ERROR_STOP=1 -U postgres -d invips \
    -v usuario="$USUARIO" -v senha="$senha" <<SQL
CREATE ROLE :"usuario" LOGIN PASSWORD :'"'"'senha'"'"' IN ROLE invips_leitor;
SQL
  echo "usuário $USUARIO criado (só leitura). Senha: $senha"
'
