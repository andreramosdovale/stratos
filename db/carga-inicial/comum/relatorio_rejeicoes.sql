-- Lista as rejeições acumuladas e aborta a carga se houver alguma.
SELECT count(*) > 0 AS ha_rejeicoes FROM pg_temp.rejeicao \gset
\if :ha_rejeicoes
  \o
  \echo 'Linhas rejeitadas (arquivo, linha, motivo):'
  SELECT arquivo, linha, motivo FROM pg_temp.rejeicao ORDER BY arquivo, linha, motivo LIMIT 500;
  \o /dev/null
\endif
SELECT pg_temp.abortar_se_rejeitado();
\o
