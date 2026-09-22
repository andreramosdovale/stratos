-- nucleo: staging -> esquemas finais
INSERT INTO nucleo.lote_carga (conjunto, arquivos)
VALUES ('nucleo', :'arquivos'::jsonb)
RETURNING id AS lote_id \gset

INSERT INTO nucleo.municipio (codigo_ibge, nome, uf_id)
SELECT s.codigo_ibge::integer, s.nome, u.id
FROM staging.municipios s JOIN nucleo.uf u ON u.sigla = s.uf;

INSERT INTO nucleo.fonte_dado (nome, descricao, url)
SELECT nome, descricao, url FROM staging.fontes;

\echo 'lote' :lote_id 'gravado:'
SELECT 'nucleo.municipio' AS tabela, count(*) AS registros FROM nucleo.municipio
UNION ALL SELECT 'nucleo.fonte_dado', count(*) FROM nucleo.fonte_dado;

\o /dev/null
SELECT pg_temp.esvaziar_staging();
