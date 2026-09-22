-- Dicionário de dados consultável (RF-11) e visão de qualidade (RF-5).

CREATE VIEW nucleo.v_dicionario_dados AS
SELECT
  n.nspname                                   AS esquema,
  c.relname                                   AS tabela,
  CASE c.relkind WHEN 'v' THEN 'visão' ELSE 'tabela' END AS tipo_objeto,
  obj_description(c.oid, 'pg_class')          AS descricao_tabela,
  a.attnum                                    AS posicao,
  a.attname                                   AS coluna,
  format_type(a.atttypid, a.atttypmod)        AS tipo,
  NOT a.attnotnull                            AS aceita_nulo,
  col_description(c.oid, a.attnum)            AS descricao_coluna
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum > 0 AND NOT a.attisdropped
WHERE n.nspname IN ('nucleo', 'infraestrutura', 'noticias')
  AND c.relkind IN ('r', 'v');
COMMENT ON VIEW nucleo.v_dicionario_dados IS 'Dicionário de dados: tabelas, colunas, tipos e descrições dos esquemas de dados.';
COMMENT ON COLUMN nucleo.v_dicionario_dados.esquema IS 'Esquema.';
COMMENT ON COLUMN nucleo.v_dicionario_dados.tabela IS 'Tabela ou visão.';
COMMENT ON COLUMN nucleo.v_dicionario_dados.tipo_objeto IS 'tabela ou visão.';
COMMENT ON COLUMN nucleo.v_dicionario_dados.descricao_tabela IS 'Descrição da tabela.';
COMMENT ON COLUMN nucleo.v_dicionario_dados.posicao IS 'Posição da coluna na tabela.';
COMMENT ON COLUMN nucleo.v_dicionario_dados.coluna IS 'Nome da coluna.';
COMMENT ON COLUMN nucleo.v_dicionario_dados.tipo IS 'Tipo de dado.';
COMMENT ON COLUMN nucleo.v_dicionario_dados.aceita_nulo IS 'Se a coluna aceita nulo.';
COMMENT ON COLUMN nucleo.v_dicionario_dados.descricao_coluna IS 'Descrição da coluna.';

CREATE VIEW noticias.v_qualidade_por_eixo AS
WITH registros AS (
            SELECT 'municipios'           AS eixo, origem, validado_por_humano FROM noticias.noticia_municipio
  UNION ALL SELECT 'pessoas_envolvidas',           origem, validado_por_humano FROM noticias.noticia_pessoa
  UNION ALL SELECT 'homicidio',                    origem, validado_por_humano FROM noticias.homicidio_noticiado
  UNION ALL SELECT 'estrutura_faccional',          origem, validado_por_humano FROM noticias.estrutura_faccional
  UNION ALL SELECT 'disputas_territoriais',        origem, validado_por_humano FROM noticias.disputa_territorial
  UNION ALL SELECT 'confrontos_aliancas',          origem, validado_por_humano FROM noticias.relacao_faccional
  UNION ALL SELECT 'lavagem_dinheiro',             origem, validado_por_humano FROM noticias.lavagem_dinheiro
  UNION ALL SELECT 'atividades_ilicitas',          origem, validado_por_humano FROM noticias.atividade_ilicita
  UNION ALL SELECT 'atuacao_politica',             origem, validado_por_humano FROM noticias.atuacao_politica
  UNION ALL SELECT 'apreensoes',                   origem, validado_por_humano FROM noticias.apreensao
  UNION ALL SELECT 'operacoes_policiais',          origem, validado_por_humano FROM noticias.operacao_policial
)
SELECT
  eixo,
  count(*)                                              AS total,
  count(*) FILTER (WHERE origem = 'llm')                AS por_llm,
  count(*) FILTER (WHERE validado_por_humano)           AS validados,
  round(100.0 * count(*) FILTER (WHERE validado_por_humano) / count(*), 1) AS pct_validados
FROM registros
GROUP BY eixo;
COMMENT ON VIEW noticias.v_qualidade_por_eixo IS 'Proporção de registros validados por humanos em cada eixo informacional.';
COMMENT ON COLUMN noticias.v_qualidade_por_eixo.eixo IS 'Eixo informacional.';
COMMENT ON COLUMN noticias.v_qualidade_por_eixo.total IS 'Total de registros no eixo.';
COMMENT ON COLUMN noticias.v_qualidade_por_eixo.por_llm IS 'Registros preenchidos por LLM.';
COMMENT ON COLUMN noticias.v_qualidade_por_eixo.validados IS 'Registros validados por humano.';
COMMENT ON COLUMN noticias.v_qualidade_por_eixo.pct_validados IS 'Percentual validado.';
