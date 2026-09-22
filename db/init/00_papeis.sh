#!/bin/bash
# Executado uma única vez, na criação do cluster (docker-entrypoint-initdb.d).
# Cria os papéis e fecha o acesso padrão. Esquemas e privilégios sobre
# objetos ficam nas migrações (db/migrations).
set -eo pipefail

: "${INVIPS_ADMIN_PASSWORD:?defina INVIPS_ADMIN_PASSWORD no .env}"
: "${INVIPS_CURADOR_PASSWORD:?defina INVIPS_CURADOR_PASSWORD no .env}"
: "${INVIPS_BACKUP_PASSWORD:?defina INVIPS_BACKUP_PASSWORD no .env}"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
  -v admin_pw="$INVIPS_ADMIN_PASSWORD" \
  -v curador_pw="$INVIPS_CURADOR_PASSWORD" \
  -v backup_pw="$INVIPS_BACKUP_PASSWORD" <<'SQL'
CREATE ROLE invips_admin   LOGIN PASSWORD :'admin_pw';
CREATE ROLE invips_curador LOGIN PASSWORD :'curador_pw';
CREATE ROLE invips_leitor  NOLOGIN;
CREATE ROLE invips_backup  LOGIN PASSWORD :'backup_pw';

GRANT invips_leitor TO invips_curador;
GRANT pg_read_all_data TO invips_backup;

-- O admin é dono do banco para poder criar esquemas pelas migrações.
ALTER DATABASE invips OWNER TO invips_admin;

REVOKE ALL ON DATABASE invips FROM PUBLIC;
GRANT CONNECT ON DATABASE invips TO invips_leitor, invips_backup;
GRANT CONNECT, TEMPORARY ON DATABASE invips TO invips_curador;

REVOKE ALL ON SCHEMA public FROM PUBLIC;
ALTER SCHEMA public OWNER TO invips_admin;

ALTER DATABASE invips SET timezone TO 'America/Sao_Paulo';
SQL
