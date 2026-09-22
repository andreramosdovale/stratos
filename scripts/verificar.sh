#!/usr/bin/env bash
# Verificação automatizada dos critérios de aceite (spec §7) sobre o ambiente
# em execução. Não altera dados: os testes de escrita rodam em transações
# desfeitas com ROLLBACK.
#
#   scripts/verificar.sh
#
# Critérios que dependem de ciclos destrutivos (reconstrução do zero, carga
# rejeitada) têm roteiro manual em docs/RUNBOOK.md.
set -uo pipefail
export MSYS_NO_PATHCONV=1
cd "$(dirname "$0")/.."

falhas=0
ok()    { echo "  OK     $1"; }
falha() { echo "  FALHA  $1${2:+ -> $2}"; falhas=$((falhas + 1)); }

# Consulta como superusuário (dentro do contêiner, socket local)
pg() {
  docker compose exec -T -e Q="$1" db sh -c \
    'PGPASSWORD="$POSTGRES_PASSWORD" psql -X -At -v ON_ERROR_STOP=1 -U postgres -d invips -c "$Q"' 2>&1
}
# Executa um script SQL como um usuário com login real (via TCP, pg_hba)
como() {
  local usuario="$1" var="$2" sql="$3"
  docker compose exec -T -e Q="$sql" -e U="$usuario" -e V="$var" db sh -c \
    'PGPASSWORD="$(printenv "$V")" psql -X -At -v ON_ERROR_STOP=1 -h 127.0.0.1 -U "$U" -d invips -c "$Q"' 2>&1
}
espera() {  # espera <descrição> <esperado> <obtido>
  if [ "$2" = "$3" ]; then ok "$1"; else falha "$1" "esperado '$2', obtido '$3'"; fi
}
nega() {    # nega <descrição> <saída>: a operação precisa ser negada (sem privilégio ou sem posse)
  if grep -qE "permission denied|must be owner" <<<"$2"; then ok "$1"; else falha "$1" "$(head -1 <<<"$2")"; fi
}

echo "Ambiente"
espera "db healthy" "healthy" "$(docker inspect -f '{{.State.Health.Status}}' "$(docker compose ps -q db)")"
espera "migrações aplicadas (5)" "5" "$(pg "SELECT count(*) FROM migracao.flyway_schema_history WHERE success AND version IS NOT NULL")"
espera "imagem com versão fixa" "0" "$(grep -cE 'image: .*:latest|image: [^:]+$' docker-compose.yml)"

echo "Segurança"
espera "data_checksums = on" "on" "$(pg 'SHOW data_checksums')"
espera "password_encryption = scram-sha-256" "scram-sha-256" "$(pg 'SHOW password_encryption')"
espera "pg_hba sem trust" "0" "$(grep -vE '^\s*#' db/config/pg_hba.conf | grep -c trust)"
espera "pg_hba em uso é o do projeto" "/etc/postgresql/pg_hba.conf" "$(pg 'SHOW hba_file')"
espera "porta só em 127.0.0.1" "127.0.0.1:5432" "$(docker compose port db 5432)"
espera ".env ignorado no git" "1" "$(grep -cx '.env' .gitignore)"
espera ".env.example sem valores de senha" "0" "$(grep -cE 'PASSWORD=.+' .env.example)"
espera "só postgres é superusuário" "postgres" "$(pg "SELECT string_agg(rolname, ',') FROM pg_roles WHERE rolsuper")"

echo "Papéis"
leitor_select=$(pg "SET ROLE invips_leitor; SELECT count(*) > 0 FROM noticias.noticia")
espera "leitor: SELECT funciona" "t" "$(tail -1 <<<"$leitor_select")"
nega "leitor: INSERT negado" "$(pg "SET ROLE invips_leitor; INSERT INTO nucleo.faccao (nome) VALUES ('x')")"
nega "leitor: UPDATE negado" "$(pg "SET ROLE invips_leitor; UPDATE nucleo.faccao SET nome = nome")"
nega "leitor: DELETE negado" "$(pg "SET ROLE invips_leitor; DELETE FROM nucleo.faccao")"
nega "leitor: CREATE negado" "$(pg "SET ROLE invips_leitor; CREATE TABLE noticias.x (a int)")"
nega "leitor: sem acesso à auditoria" "$(pg "SET ROLE invips_leitor; SELECT 1 FROM auditoria.log_alteracao LIMIT 1")"

cur_dml=$(como invips_curador INVIPS_CURADOR_PASSWORD "BEGIN;
  UPDATE nucleo.faccao SET nome = nome || ' (teste)' WHERE id = (SELECT min(id) FROM nucleo.faccao);
  SELECT count(*) FROM auditoria.log_alteracao
   WHERE tabela = 'nucleo.faccao' AND operacao = 'UPDATE' AND transacao = txid_current()
     AND dados_antigos IS NOT NULL AND dados_novos IS NOT NULL AND usuario = 'invips_curador';
  ROLLBACK;")
espera "curador: DML funciona e gera auditoria com antes/depois" "1" "$(grep -E '^[0-9]+$' <<<"$cur_dml" | tail -1)"
nega "curador: CREATE negado" "$(como invips_curador INVIPS_CURADOR_PASSWORD "CREATE TABLE noticias.x (a int)")"
nega "curador: ALTER negado" "$(como invips_curador INVIPS_CURADOR_PASSWORD "ALTER TABLE noticias.noticia ADD COLUMN x int")"
nega "curador: DROP negado" "$(como invips_curador INVIPS_CURADOR_PASSWORD "DROP TABLE noticias.apreensao")"
nega "curador: não apaga auditoria" "$(como invips_curador INVIPS_CURADOR_PASSWORD "DELETE FROM auditoria.log_alteracao")"
nega "curador: não altera auditoria" "$(como invips_curador INVIPS_CURADOR_PASSWORD "UPDATE auditoria.log_alteracao SET usuario = 'x'")"

echo "Modelo"
espera "4 eixos de infraestrutura" "4" "$(pg "SELECT count(*) FROM infraestrutura.ref_eixo")"
espera "11 eixos de notícias representados" "11" "$(pg "SELECT count(*) FROM (SELECT DISTINCT obj_description(c.oid) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'noticias' AND c.relkind = 'r' AND obj_description(c.oid) ~ '^Eixo [0-9]+') e")"
espera "FKs válidas (nenhuma NOT VALID)" "0" "$(pg "SELECT count(*) FROM pg_constraint WHERE contype = 'f' AND NOT convalidated")"
espera "proveniência em todas as tabelas de eixo" "0" "$(pg "SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'noticias' AND c.relkind = 'r' AND obj_description(c.oid) ~ '^Eixo ([2-9]|1[01])' AND NOT EXISTS (SELECT 1 FROM information_schema.columns k WHERE k.table_schema = 'noticias' AND k.table_name = c.relname AND k.column_name = 'validado_por_humano')")"
espera "dicionário sem descrição vazia" "0" "$(pg "SELECT count(*) FROM nucleo.v_dicionario_dados WHERE coalesce(descricao_tabela, '') = '' OR coalesce(descricao_coluna, '') = ''")"
espera "migrações só inserem dados de referência" "0" "$(grep -hE 'INSERT INTO' db/migrations/*.sql | grep -vcE 'INSERT INTO (nucleo\.uf|[a-z_]+\.ref_[a-z_]+|auditoria\.log_alteracao) ')"
espera "carga fora do up (profile carga)" "1" "$(grep -cE 'profiles: \[\"carga\"\]' docker-compose.yml)"

echo "Consultas de referência"
for q in db/queries/*.sql; do
  saida=$(docker compose exec -T db sh -c 'PGPASSWORD="$INVIPS_CURADOR_PASSWORD" psql -X -q -v ON_ERROR_STOP=1 -h 127.0.0.1 -U invips_curador -d invips' < "$q" 2>&1)
  if [ $? -eq 0 ]; then ok "$(basename "$q")"; else falha "$(basename "$q")" "$(head -1 <<<"$saida")"; fi
done

echo
if [ "$falhas" -eq 0 ]; then echo "Todos os critérios verificados passaram."; else echo "$falhas critério(s) falharam."; fi
exit $(( falhas > 0 ))
