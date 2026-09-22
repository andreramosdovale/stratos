# Runbook de operação

Todos os comandos rodam na raiz do projeto. No Git Bash do Windows, os
scripts já exportam `MSYS_NO_PATHCONV=1`. Para comandos `docker compose`
digitados à mão com caminhos `/...`, exporte a variável antes.

## Primeira subida

```bash
cp .env.example .env        # preencha as senhas (fortes e distintas)
docker compose up -d        # db fica healthy; migrate aplica as migrações e termina
docker compose logs migrate # confirme "Successfully applied"
```

As senhas de `.env` só são lidas na **criação** do volume. Para trocá-las
depois, use `ALTER ROLE ... PASSWORD` e atualize o `.env`.

## Carga inicial

Ver [`db/carga-inicial/README.md`](../db/carga-inicial/README.md). Resumo:

```bash
docker compose --profile carga run --rm carga todos      # CSVs em ./dados/
```

## Acesso

| Quem | Como |
|---|---|
| Curador | `psql -h 127.0.0.1 -U invips_curador -d invips` (senha no `.env`) |
| Pesquisador | `scripts/criar-pesquisador.sh <usuario>` cria um login só leitura. A senha aparece uma vez. |
| Administração/DDL | Só via nova migração em `db/migrations/` (Flyway, `invips_admin`) |
| Superusuário | Só dentro do contêiner: `docker compose exec db psql -U postgres -d invips` |

A porta 5432 só escuta em `127.0.0.1`. Para acesso remoto, use um túnel SSH
até o host em vez de publicar a porta.

## Mudanças de esquema

1. Crie `db/migrations/V<n+1>__<descricao>.sql`. **Nunca edite uma migração já aplicada.**
2. Inclua `COMMENT ON` em toda tabela e coluna nova.
3. Para tabela nova num esquema de dados: `SELECT auditoria.habilitar('esquema.tabela');`
4. `docker compose up migrate`, depois `scripts/gerar-dicionario.sh` e `scripts/verificar.sh`.

## Backup

```bash
scripts/backup.sh     # backups/invips-AAAAMMDD-HHMMSS.dump + .sha256; apaga os > BACKUP_RETENCAO_DIAS
```

Agendamento diário (RPO 24 h):

- **Linux/macOS (cron):** `0 2 * * * cd /caminho/stratos && scripts/backup.sh >> backups/backup.log 2>&1`
- **Windows (Agendador de Tarefas):**
  ```powershell
  schtasks /Create /SC DAILY /ST 02:00 /TN "INViPS backup" /TR "\"C:\Program Files\Git\bin\bash.exe\" -lc 'cd /c/Users/<usuario>/codes/stratos && scripts/backup.sh'"
  ```

Copie `backups/` para fora do host (o destino depende da decisão de
hospedagem, Q7 da spec).

## Teste de restauração (mensal e a cada troca de versão major)

```bash
scripts/restore.sh backups/<arquivo>.dump
```

O script confere o SHA-256, restaura em `invips_restauracao`, compara a
contagem de linhas de cada tabela com `invips` e mostra o tempo gasto.
Registre abaixo. Depois do teste, apague o banco:
`docker compose exec db dropdb -U postgres invips_restauracao`.

| Data | Arquivo | Tempo | Contagens | Responsável |
|---|---|---|---|---|
| 2026-09-22 | invips-20260922-170226.dump (dados de exemplo) | 1 s | idênticas (34 tabelas) | implantação inicial |

## Recuperação de desastre

```bash
docker compose up -d db                                 # volume novo ou existente
CONFIRMAR=sim scripts/restore.sh backups/<arquivo>.dump invips
docker compose up migrate                               # aplica migrações posteriores ao backup, se houver
scripts/verificar.sh
```

## Upgrade de versão major do PostgreSQL

1. `scripts/backup.sh`
2. Troque a tag em `docker-compose.yml` (serviços `db` e `carga`).
3. `docker compose down` e renomeie ou remova o volume `invips_pgdata`.
4. `docker compose up -d`, depois `CONFIRMAR=sim scripts/restore.sh <backup> invips`.
5. `scripts/verificar.sh` e registre um teste de restauração.

## Verificação dos critérios de aceite

```bash
scripts/verificar.sh
```

Critérios destrutivos, para rodar num ambiente descartável:

- **Reconstrução do zero (RF-2):** guarde `pg_dump --schema-only`,
  rode `docker compose down -v && docker compose up -d` e compare de novo
  (ignore as linhas `\restrict`, que mudam a cada dump).
- **Carga rejeitada (RF-8):** num banco vazio, copie `db/carga-inicial/exemplo/nucleo`
  para `dados/teste/nucleo`, acrescente uma linha inválida em `municipios.csv`
  e rode `docker compose --profile carga run --rm carga nucleo /dados/teste`.
  Espere a lista de rejeições e `nucleo.lote_carga` vazio.
