-- noticias: validação. Acumula rejeições e aborta se houver alguma.
SELECT pg_temp.exigir_carregado('nucleo');

-- noticias.csv (eixo 1: identificadores básicos)
SELECT pg_temp.checar_obrigatorio('noticias', 'id_noticia', 'veiculo', 'url', 'titulo', 'data_publicacao');
SELECT pg_temp.checar_tipo('noticias', 'data_publicacao', 'date');
SELECT pg_temp.checar('noticias',
  $c$CASE WHEN pg_input_is_valid(data_publicacao, 'date')
          THEN data_publicacao::date NOT BETWEEN '2015-01-01' AND '2023-12-31' ELSE false END$c$,
  $m$'data_publicacao fora de 2015–2023: ' || data_publicacao$m$);
SELECT pg_temp.checar_unico('noticias', 'id_noticia');
SELECT pg_temp.checar_unico('noticias', 'url');

-- Regras comuns a todos os arquivos de eixo: notícia existente e proveniência
DO $$
DECLARE
  nome text;
BEGIN
  FOREACH nome IN ARRAY ARRAY['noticia_municipios', 'noticia_pessoas', 'homicidios_noticiados',
    'estrutura_faccional', 'disputas_territoriais', 'relacoes_faccionais', 'lavagem_dinheiro',
    'atividades_ilicitas', 'atuacao_politica', 'operacoes_policiais', 'apreensoes']
  LOOP
    PERFORM pg_temp.checar_obrigatorio(nome, 'id_noticia');
    PERFORM pg_temp.checar_ref(nome, 'id_noticia',
      'SELECT id_noticia FROM staging.noticias WHERE id_noticia IS NOT NULL', 'noticias.csv');
    PERFORM pg_temp.checar_proveniencia(nome);
  END LOOP;

  -- Arquivos com município opcional
  FOREACH nome IN ARRAY ARRAY['noticia_municipios', 'homicidios_noticiados', 'disputas_territoriais',
    'operacoes_policiais', 'apreensoes']
  LOOP
    PERFORM pg_temp.checar_ref(nome, 'codigo_ibge',
      'SELECT codigo_ibge::text FROM nucleo.municipio', 'nucleo.municipio');
  END LOOP;

  -- Arquivos que citam pessoas: nome obrigatório quando há chave
  FOREACH nome IN ARRAY ARRAY['noticia_pessoas', 'estrutura_faccional', 'atuacao_politica'] LOOP
    PERFORM pg_temp.checar(nome, 'pessoa_chave IS NOT NULL AND pessoa_nome IS NULL',
      '''pessoa_nome é obrigatório quando pessoa_chave é informada''');
  END LOOP;
END $$;

-- noticia_municipios.csv
SELECT pg_temp.checar_obrigatorio('noticia_municipios', 'codigo_ibge');
SELECT pg_temp.checar_unico('noticia_municipios', 'id_noticia, codigo_ibge');

-- noticia_pessoas.csv (eixo 2)
SELECT pg_temp.checar_obrigatorio('noticia_pessoas', 'pessoa_nome', 'papel');
SELECT pg_temp.checar_ref('noticia_pessoas', 'papel', 'SELECT codigo FROM noticias.ref_papel_pessoa', 'noticias.ref_papel_pessoa');
SELECT pg_temp.checar_unico('noticia_pessoas', 'id_noticia, coalesce(pessoa_chave, pessoa_nome), papel');

-- Uma chave de pessoa não pode apontar para nomes diferentes entre arquivos
CREATE TEMP VIEW pessoas_citadas AS
            SELECT 'noticia_pessoas.csv' AS arquivo, linha, coalesce(pessoa_chave, pessoa_nome) AS chave, pessoa_nome AS nome FROM staging.noticia_pessoas
  UNION ALL SELECT 'estrutura_faccional.csv', linha, coalesce(pessoa_chave, pessoa_nome), pessoa_nome FROM staging.estrutura_faccional
  UNION ALL SELECT 'atuacao_politica.csv',    linha, coalesce(pessoa_chave, pessoa_nome), pessoa_nome FROM staging.atuacao_politica;

INSERT INTO pg_temp.rejeicao (arquivo, linha, motivo)
SELECT p.arquivo, p.linha, 'pessoa_chave "' || p.chave || '" usada com nomes diferentes'
FROM pessoas_citadas p
WHERE p.chave IN (
  SELECT chave FROM pessoas_citadas WHERE chave IS NOT NULL
  GROUP BY chave HAVING count(DISTINCT nome) > 1);

-- homicidios_noticiados.csv (eixo 3)
SELECT pg_temp.checar_obrigatorio('homicidios_noticiados', 'qtd_vitimas');
SELECT pg_temp.checar_tipo('homicidios_noticiados', 'data_fato', 'date');
SELECT pg_temp.checar_tipo('homicidios_noticiados', 'qtd_vitimas', 'integer');
SELECT pg_temp.checar_minimo('homicidios_noticiados', 'qtd_vitimas', 'integer', 1);

-- estrutura_faccional.csv (eixo 4)
SELECT pg_temp.checar_obrigatorio('estrutura_faccional', 'faccao');

-- disputas_territoriais.csv (eixo 5)
SELECT pg_temp.checar_obrigatorio('disputas_territoriais', 'territorio');

-- relacoes_faccionais.csv (eixo 6)
SELECT pg_temp.checar_obrigatorio('relacoes_faccionais', 'faccao_a', 'faccao_b', 'tipo');
SELECT pg_temp.checar_ref('relacoes_faccionais', 'tipo', 'SELECT codigo FROM noticias.ref_tipo_relacao', 'noticias.ref_tipo_relacao');
SELECT pg_temp.checar('relacoes_faccionais', 'faccao_a = faccao_b',
  $m$'faccao_a e faccao_b devem ser diferentes: ' || faccao_a$m$);

-- lavagem_dinheiro.csv (eixo 7)
SELECT pg_temp.checar_obrigatorio('lavagem_dinheiro', 'mecanismo');
SELECT pg_temp.checar_tipo('lavagem_dinheiro', 'valor_estimado', 'numeric(18,2)');
SELECT pg_temp.checar_minimo('lavagem_dinheiro', 'valor_estimado', 'numeric', 0);

-- atividades_ilicitas.csv (eixo 8)
SELECT pg_temp.checar_obrigatorio('atividades_ilicitas', 'tipo');
SELECT pg_temp.checar_ref('atividades_ilicitas', 'tipo', 'SELECT codigo FROM noticias.ref_tipo_atividade', 'noticias.ref_tipo_atividade');

-- atuacao_politica.csv (eixo 9)
SELECT pg_temp.checar_obrigatorio('atuacao_politica', 'descricao');

-- operacoes_policiais.csv (eixo 11)
SELECT pg_temp.checar_obrigatorio('operacoes_policiais', 'id_operacao');
SELECT pg_temp.checar_unico('operacoes_policiais', 'id_noticia, id_operacao');
SELECT pg_temp.checar_tipo('operacoes_policiais', 'data_operacao', 'date');
SELECT pg_temp.checar_tipo('operacoes_policiais', 'qtd_presos', 'integer');
SELECT pg_temp.checar_minimo('operacoes_policiais', 'qtd_presos', 'integer', 0);
SELECT pg_temp.checar_tipo('operacoes_policiais', 'qtd_mortos', 'integer');
SELECT pg_temp.checar_minimo('operacoes_policiais', 'qtd_mortos', 'integer', 0);

-- apreensoes.csv (eixo 10)
SELECT pg_temp.checar_obrigatorio('apreensoes', 'item');
SELECT pg_temp.checar_ref('apreensoes', 'item', 'SELECT codigo FROM noticias.ref_tipo_item', 'noticias.ref_tipo_item');
SELECT pg_temp.checar_tipo('apreensoes', 'quantidade', 'numeric');
SELECT pg_temp.checar_minimo('apreensoes', 'quantidade', 'numeric', 0);
SELECT pg_temp.checar('apreensoes', 'quantidade IS NOT NULL AND unidade IS NULL',
  $m$'unidade é obrigatória quando há quantidade'$m$);
SELECT pg_temp.checar('apreensoes',
  $c$id_operacao IS NOT NULL AND (id_noticia, id_operacao) NOT IN
     (SELECT id_noticia, id_operacao FROM staging.operacoes_policiais
      WHERE id_noticia IS NOT NULL AND id_operacao IS NOT NULL)$c$,
  $m$'id_operacao não encontrado em operacoes_policiais.csv para a mesma notícia: ' || id_operacao$m$);

\ir ../comum/relatorio_rejeicoes.sql
