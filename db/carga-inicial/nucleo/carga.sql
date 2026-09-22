-- Carga inicial do conjunto "nucleo". Executada por executar.sh numa única transação.
\set ON_ERROR_STOP on
-- Saída das chamadas de validação suprimida; o relatório de rejeições reativa.
\o /dev/null
\ir ../comum/funcoes.sql
SELECT pg_temp.exigir_primeira_carga('nucleo');
\ir 01_staging.sql
\ir 02_validacao.sql
\ir 03_transformacao.sql
