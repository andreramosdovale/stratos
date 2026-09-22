-- noticias: staging -> esquemas finais
INSERT INTO nucleo.lote_carga (conjunto, arquivos)
VALUES ('noticias', :'arquivos'::jsonb)
RETURNING id AS lote_id \gset

-- Colunas de proveniência, iguais em todos os eixos
\set prov 's.origem, s.modelo_llm, coalesce(s.validado_por_humano, ''false'')::boolean, s.validado_em::timestamptz, ' :lote_id
\set prov_cols 'origem, modelo_llm, validado_por_humano, validado_em, lote_carga_id'

-- Entidades compartilhadas: veículos, pessoas e facções
INSERT INTO nucleo.veiculo_imprensa (nome)
SELECT DISTINCT veiculo FROM staging.noticias
ON CONFLICT (nome) DO NOTHING;

INSERT INTO nucleo.pessoa (chave_origem, nome)
SELECT DISTINCT chave, nome FROM pessoas_citadas WHERE chave IS NOT NULL
ON CONFLICT (chave_origem) DO NOTHING;

CREATE TEMP TABLE faccoes_novas AS
WITH citadas AS (
            SELECT faccao AS nome FROM staging.estrutura_faccional
  UNION     SELECT btrim(f) FROM staging.disputas_territoriais, unnest(string_to_array(faccoes, '|')) AS f
  UNION     SELECT faccao_a FROM staging.relacoes_faccionais
  UNION     SELECT faccao_b FROM staging.relacoes_faccionais
  UNION     SELECT faccao FROM staging.lavagem_dinheiro
  UNION     SELECT faccao FROM staging.atividades_ilicitas
  UNION     SELECT faccao FROM staging.atuacao_politica
)
SELECT nome FROM citadas
WHERE nome IS NOT NULL AND nome <> ''
  AND nome NOT IN (SELECT nome FROM nucleo.faccao);

INSERT INTO nucleo.faccao (nome) SELECT nome FROM faccoes_novas;

-- Eixo 1: notícia
INSERT INTO noticias.noticia (codigo_origem, veiculo_id, url, titulo, data_publicacao, resumo, lote_carga_id)
SELECT s.id_noticia, v.id, s.url, s.titulo, s.data_publicacao::date, s.resumo, :lote_id
FROM staging.noticias s
JOIN nucleo.veiculo_imprensa v ON v.nome = s.veiculo;

INSERT INTO noticias.noticia_municipio (noticia_id, municipio_id, :prov_cols)
SELECT n.id, m.id, :prov
FROM staging.noticia_municipios s
JOIN noticias.noticia n ON n.codigo_origem = s.id_noticia
JOIN nucleo.municipio m ON m.codigo_ibge::text = s.codigo_ibge;

-- Eixo 2: pessoas envolvidas
INSERT INTO noticias.noticia_pessoa (noticia_id, pessoa_id, papel, :prov_cols)
SELECT n.id, p.id, s.papel, :prov
FROM staging.noticia_pessoas s
JOIN noticias.noticia n ON n.codigo_origem = s.id_noticia
JOIN nucleo.pessoa p ON p.chave_origem = coalesce(s.pessoa_chave, s.pessoa_nome);

-- Eixo 3: homicídio
INSERT INTO noticias.homicidio_noticiado
  (noticia_id, municipio_id, data_fato, qtd_vitimas, meio_empregado, motivacao, :prov_cols)
SELECT n.id, m.id, s.data_fato::date, s.qtd_vitimas::integer, s.meio_empregado, s.motivacao, :prov
FROM staging.homicidios_noticiados s
JOIN noticias.noticia n ON n.codigo_origem = s.id_noticia
LEFT JOIN nucleo.municipio m ON m.codigo_ibge::text = s.codigo_ibge;

-- Eixo 4: estrutura faccional
INSERT INTO noticias.estrutura_faccional
  (noticia_id, faccao_id, pessoa_id, cargo_funcao, descricao, :prov_cols)
SELECT n.id, f.id, p.id, s.cargo_funcao, s.descricao, :prov
FROM staging.estrutura_faccional s
JOIN noticias.noticia n ON n.codigo_origem = s.id_noticia
JOIN nucleo.faccao f ON f.nome = s.faccao
LEFT JOIN nucleo.pessoa p ON p.chave_origem = coalesce(s.pessoa_chave, s.pessoa_nome);

-- Eixo 5: disputas territoriais (ids reservados para ligar as facções de cada linha)
CREATE TEMP TABLE mapa_disputa AS
SELECT s.linha, nextval(pg_get_serial_sequence('noticias.disputa_territorial', 'id')) AS id
FROM staging.disputas_territoriais s;

INSERT INTO noticias.disputa_territorial
  (id, noticia_id, municipio_id, territorio, descricao, :prov_cols)
OVERRIDING SYSTEM VALUE
SELECT md.id, n.id, m.id, s.territorio, s.descricao, :prov
FROM staging.disputas_territoriais s
JOIN mapa_disputa md ON md.linha = s.linha
JOIN noticias.noticia n ON n.codigo_origem = s.id_noticia
LEFT JOIN nucleo.municipio m ON m.codigo_ibge::text = s.codigo_ibge;

INSERT INTO noticias.disputa_faccao (disputa_id, faccao_id)
SELECT DISTINCT md.id, f.id
FROM staging.disputas_territoriais s
JOIN mapa_disputa md ON md.linha = s.linha
CROSS JOIN LATERAL unnest(string_to_array(s.faccoes, '|')) AS item(nome)
JOIN nucleo.faccao f ON f.nome = btrim(item.nome);

-- Eixo 6: confrontos e alianças
INSERT INTO noticias.relacao_faccional
  (noticia_id, faccao_a_id, faccao_b_id, tipo, descricao, :prov_cols)
SELECT n.id, fa.id, fb.id, s.tipo, s.descricao, :prov
FROM staging.relacoes_faccionais s
JOIN noticias.noticia n ON n.codigo_origem = s.id_noticia
JOIN nucleo.faccao fa ON fa.nome = s.faccao_a
JOIN nucleo.faccao fb ON fb.nome = s.faccao_b;

-- Eixo 7: lavagem de dinheiro
INSERT INTO noticias.lavagem_dinheiro
  (noticia_id, faccao_id, mecanismo, valor_estimado, descricao, :prov_cols)
SELECT n.id, f.id, s.mecanismo, s.valor_estimado::numeric, s.descricao, :prov
FROM staging.lavagem_dinheiro s
JOIN noticias.noticia n ON n.codigo_origem = s.id_noticia
LEFT JOIN nucleo.faccao f ON f.nome = s.faccao;

-- Eixo 8: atividades econômicas ilícitas
INSERT INTO noticias.atividade_ilicita (noticia_id, faccao_id, tipo, descricao, :prov_cols)
SELECT n.id, f.id, s.tipo, s.descricao, :prov
FROM staging.atividades_ilicitas s
JOIN noticias.noticia n ON n.codigo_origem = s.id_noticia
LEFT JOIN nucleo.faccao f ON f.nome = s.faccao;

-- Eixo 9: atuação política
INSERT INTO noticias.atuacao_politica
  (noticia_id, faccao_id, pessoa_id, cargo, descricao, :prov_cols)
SELECT n.id, f.id, p.id, s.cargo, s.descricao, :prov
FROM staging.atuacao_politica s
JOIN noticias.noticia n ON n.codigo_origem = s.id_noticia
LEFT JOIN nucleo.faccao f ON f.nome = s.faccao
LEFT JOIN nucleo.pessoa p ON p.chave_origem = coalesce(s.pessoa_chave, s.pessoa_nome);

-- Eixo 11: operações policiais
INSERT INTO noticias.operacao_policial
  (noticia_id, codigo_origem, nome_operacao, orgao, municipio_id, data_operacao,
   qtd_presos, qtd_mortos, :prov_cols)
SELECT n.id, s.id_operacao, s.nome_operacao, s.orgao, m.id, s.data_operacao::date,
       s.qtd_presos::integer, s.qtd_mortos::integer, :prov
FROM staging.operacoes_policiais s
JOIN noticias.noticia n ON n.codigo_origem = s.id_noticia
LEFT JOIN nucleo.municipio m ON m.codigo_ibge::text = s.codigo_ibge;

-- Eixo 10: apreensões
INSERT INTO noticias.apreensao
  (noticia_id, operacao_id, municipio_id, item, quantidade, unidade, descricao, :prov_cols)
SELECT n.id, o.id, m.id, s.item, s.quantidade::numeric, s.unidade, s.descricao, :prov
FROM staging.apreensoes s
JOIN noticias.noticia n ON n.codigo_origem = s.id_noticia
LEFT JOIN noticias.operacao_policial o ON o.noticia_id = n.id AND o.codigo_origem = s.id_operacao
LEFT JOIN nucleo.municipio m ON m.codigo_ibge::text = s.codigo_ibge;

\echo 'lote' :lote_id 'gravado. Facções novas criadas:'
SELECT nome FROM faccoes_novas ORDER BY nome;
SELECT 'noticias.noticia' AS tabela, count(*) AS registros FROM noticias.noticia
UNION ALL SELECT 'noticias.noticia_municipio', count(*) FROM noticias.noticia_municipio
UNION ALL SELECT 'noticias.noticia_pessoa', count(*) FROM noticias.noticia_pessoa
UNION ALL SELECT 'noticias.homicidio_noticiado', count(*) FROM noticias.homicidio_noticiado
UNION ALL SELECT 'noticias.estrutura_faccional', count(*) FROM noticias.estrutura_faccional
UNION ALL SELECT 'noticias.disputa_territorial', count(*) FROM noticias.disputa_territorial
UNION ALL SELECT 'noticias.disputa_faccao', count(*) FROM noticias.disputa_faccao
UNION ALL SELECT 'noticias.relacao_faccional', count(*) FROM noticias.relacao_faccional
UNION ALL SELECT 'noticias.lavagem_dinheiro', count(*) FROM noticias.lavagem_dinheiro
UNION ALL SELECT 'noticias.atividade_ilicita', count(*) FROM noticias.atividade_ilicita
UNION ALL SELECT 'noticias.atuacao_politica', count(*) FROM noticias.atuacao_politica
UNION ALL SELECT 'noticias.operacao_policial', count(*) FROM noticias.operacao_policial
UNION ALL SELECT 'noticias.apreensao', count(*) FROM noticias.apreensao;

\o /dev/null
SELECT pg_temp.esvaziar_staging();
