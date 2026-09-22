-- infraestrutura: staging -> esquemas finais
INSERT INTO nucleo.lote_carga (conjunto, arquivos)
VALUES ('infraestrutura', :'arquivos'::jsonb)
RETURNING id AS lote_id \gset

INSERT INTO infraestrutura.homicidio (municipio_id, ano, quantidade, fonte_dado_id, lote_carga_id)
SELECT m.id, s.ano::smallint, s.quantidade::integer, f.id, :lote_id
FROM staging.homicidios s
JOIN nucleo.municipio m ON m.codigo_ibge = s.codigo_ibge::integer
JOIN nucleo.fonte_dado f ON f.nome = s.fonte;

INSERT INTO infraestrutura.indicador (codigo, eixo, nome, unidade, descricao)
SELECT codigo, eixo, nome, unidade, descricao FROM staging.indicadores;

INSERT INTO infraestrutura.medicao_indicador
  (municipio_id, ano, indicador_id, valor, fonte_dado_id, lote_carga_id)
SELECT m.id, s.ano::smallint, i.id, s.valor::numeric, f.id, :lote_id
FROM staging.medicoes s
JOIN nucleo.municipio m ON m.codigo_ibge = s.codigo_ibge::integer
JOIN infraestrutura.indicador i ON i.codigo = s.indicador
JOIN nucleo.fonte_dado f ON f.nome = s.fonte;

INSERT INTO infraestrutura.banco_desenvolvimento (sigla, nome, abrangencia)
SELECT sigla, nome, abrangencia FROM staging.bancos;

INSERT INTO infraestrutura.projeto_financiado
  (codigo_origem, banco_id, titulo, eixo, valor_contratado, data_contratacao, situacao,
   fonte_dado_id, lote_carga_id)
SELECT s.codigo_origem, b.id, s.titulo, s.eixo, s.valor_contratado::numeric,
       s.data_contratacao::date, s.situacao, f.id, :lote_id
FROM staging.projetos s
JOIN infraestrutura.banco_desenvolvimento b ON b.sigla = s.banco
JOIN nucleo.fonte_dado f ON f.nome = s.fonte;

INSERT INTO infraestrutura.projeto_municipio (projeto_id, municipio_id)
SELECT DISTINCT p.id, m.id
FROM staging.projetos s
JOIN infraestrutura.banco_desenvolvimento b ON b.sigla = s.banco
JOIN infraestrutura.projeto_financiado p ON p.banco_id = b.id AND p.codigo_origem = s.codigo_origem
CROSS JOIN LATERAL unnest(string_to_array(s.municipios, '|')) AS cod
JOIN nucleo.municipio m ON m.codigo_ibge = btrim(cod)::integer;

\echo 'lote' :lote_id 'gravado:'
SELECT 'infraestrutura.homicidio' AS tabela, count(*) AS registros FROM infraestrutura.homicidio
UNION ALL SELECT 'infraestrutura.indicador', count(*) FROM infraestrutura.indicador
UNION ALL SELECT 'infraestrutura.medicao_indicador', count(*) FROM infraestrutura.medicao_indicador
UNION ALL SELECT 'infraestrutura.banco_desenvolvimento', count(*) FROM infraestrutura.banco_desenvolvimento
UNION ALL SELECT 'infraestrutura.projeto_financiado', count(*) FROM infraestrutura.projeto_financiado
UNION ALL SELECT 'infraestrutura.projeto_municipio', count(*) FROM infraestrutura.projeto_municipio;

\o /dev/null
SELECT pg_temp.esvaziar_staging();
