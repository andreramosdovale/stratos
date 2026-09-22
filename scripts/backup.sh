#!/usr/bin/env bash
# Backup lógico diário (RF-9): gera backups/invips-AAAAMMDD-HHMMSS.dump + .sha256
# e remove backups mais antigos que BACKUP_RETENCAO_DIAS (padrão 30).
# Agendamento: ver docs/RUNBOOK.md.
set -euo pipefail
export MSYS_NO_PATHCONV=1   # Git Bash no Windows: não converter /backups
cd "$(dirname "$0")/.."

retencao="$(grep -E '^BACKUP_RETENCAO_DIAS=' .env 2>/dev/null | cut -d= -f2 || true)"
retencao="${retencao:-30}"
arquivo="invips-$(date +%Y%m%d-%H%M%S).dump"

docker compose exec -T -e ARQ="$arquivo" -e RET="$retencao" db sh -euc '
  PGPASSWORD="$INVIPS_BACKUP_PASSWORD" pg_dump -U invips_backup -d invips -Fc -f "/backups/$ARQ"
  cd /backups
  sha256sum "$ARQ" > "$ARQ.sha256"
  find /backups -maxdepth 1 -name "invips-*.dump*" -mtime +"$RET" -print -delete
'
echo "backup gerado: backups/$arquivo"
