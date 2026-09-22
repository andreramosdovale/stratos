-- Dataset de notícias e os 11 eixos informacionais.
-- Toda tabela de eixo carrega as colunas de proveniência (RF-5):
--   origem, modelo_llm, validado_por_humano, validado_em, lote_carga_id.
-- Cada fato multivalorado por notícia tem tabela própria (4FN).

-- ---------------------------------------------------------------------------
-- Domínios
-- ---------------------------------------------------------------------------

CREATE TABLE noticias.ref_papel_pessoa (codigo text PRIMARY KEY, descricao text NOT NULL);
COMMENT ON TABLE noticias.ref_papel_pessoa IS 'Domínio: papel de uma pessoa numa notícia.';
COMMENT ON COLUMN noticias.ref_papel_pessoa.codigo IS 'Código do papel.';
COMMENT ON COLUMN noticias.ref_papel_pessoa.descricao IS 'Descrição.';
INSERT INTO noticias.ref_papel_pessoa VALUES
  ('vitima', 'Vítima'), ('suspeito', 'Suspeito ou acusado'), ('preso', 'Preso'),
  ('lideranca', 'Liderança faccional'), ('agente_publico', 'Agente público de segurança'),
  ('politico', 'Agente político'), ('testemunha', 'Testemunha'), ('outro', 'Outro');

CREATE TABLE noticias.ref_tipo_relacao (codigo text PRIMARY KEY, descricao text NOT NULL);
COMMENT ON TABLE noticias.ref_tipo_relacao IS 'Domínio: tipo de relação entre facções.';
COMMENT ON COLUMN noticias.ref_tipo_relacao.codigo IS 'Código do tipo.';
COMMENT ON COLUMN noticias.ref_tipo_relacao.descricao IS 'Descrição.';
INSERT INTO noticias.ref_tipo_relacao VALUES
  ('confronto', 'Confronto'), ('alianca', 'Aliança'), ('ruptura', 'Ruptura de aliança');

CREATE TABLE noticias.ref_tipo_atividade (codigo text PRIMARY KEY, descricao text NOT NULL);
COMMENT ON TABLE noticias.ref_tipo_atividade IS 'Domínio: tipo de atividade econômica ilícita.';
COMMENT ON COLUMN noticias.ref_tipo_atividade.codigo IS 'Código do tipo.';
COMMENT ON COLUMN noticias.ref_tipo_atividade.descricao IS 'Descrição.';
INSERT INTO noticias.ref_tipo_atividade VALUES
  ('trafico_drogas', 'Tráfico de drogas'), ('trafico_armas', 'Tráfico de armas'),
  ('extorsao', 'Extorsão'), ('roubo_furto', 'Roubo ou furto'), ('contrabando', 'Contrabando'),
  ('servicos_ilegais', 'Exploração ilegal de serviços (gás, internet, transporte)'),
  ('jogo_ilegal', 'Jogo ilegal'), ('garimpo_ilegal', 'Garimpo ilegal'), ('outro', 'Outro');

CREATE TABLE noticias.ref_tipo_item (codigo text PRIMARY KEY, descricao text NOT NULL);
COMMENT ON TABLE noticias.ref_tipo_item IS 'Domínio: tipo de item apreendido.';
COMMENT ON COLUMN noticias.ref_tipo_item.codigo IS 'Código do tipo.';
COMMENT ON COLUMN noticias.ref_tipo_item.descricao IS 'Descrição.';
INSERT INTO noticias.ref_tipo_item VALUES
  ('droga', 'Droga'), ('arma', 'Arma'), ('municao', 'Munição'), ('dinheiro', 'Dinheiro'),
  ('veiculo', 'Veículo'), ('outro', 'Outro');

-- ---------------------------------------------------------------------------
-- Eixo 1: identificadores básicos
-- ---------------------------------------------------------------------------

CREATE TABLE noticias.noticia (
  id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  codigo_origem   text NOT NULL UNIQUE,
  veiculo_id      bigint NOT NULL REFERENCES nucleo.veiculo_imprensa,
  url             text NOT NULL UNIQUE,
  titulo          text NOT NULL,
  data_publicacao date NOT NULL CHECK (data_publicacao BETWEEN '2015-01-01' AND '2023-12-31'),
  resumo          text,
  lote_carga_id   bigint NOT NULL REFERENCES nucleo.lote_carga,
  criado_em       timestamptz NOT NULL DEFAULT now(),
  atualizado_em   timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE noticias.noticia IS 'Eixo 1 (identificadores básicos): uma notícia publicada.';
COMMENT ON COLUMN noticias.noticia.id IS 'Identificador interno.';
COMMENT ON COLUMN noticias.noticia.codigo_origem IS 'Identificador da notícia no dataset original.';
COMMENT ON COLUMN noticias.noticia.veiculo_id IS 'Veículo que publicou.';
COMMENT ON COLUMN noticias.noticia.url IS 'Endereço da notícia; chave natural.';
COMMENT ON COLUMN noticias.noticia.titulo IS 'Título.';
COMMENT ON COLUMN noticias.noticia.data_publicacao IS 'Data de publicação (2015–2023).';
COMMENT ON COLUMN noticias.noticia.resumo IS 'Resumo do conteúdo.';
COMMENT ON COLUMN noticias.noticia.lote_carga_id IS 'Lote de carga que trouxe o registro.';
COMMENT ON COLUMN noticias.noticia.criado_em IS 'Instante de criação do registro.';
COMMENT ON COLUMN noticias.noticia.atualizado_em IS 'Instante da última alteração do registro.';
CREATE INDEX ON noticias.noticia (data_publicacao);
CREATE INDEX ON noticias.noticia (veiculo_id);
CREATE TRIGGER tocar_atualizado_em BEFORE UPDATE ON noticias.noticia
  FOR EACH ROW EXECUTE FUNCTION nucleo.tocar_atualizado_em();

CREATE TABLE noticias.noticia_municipio (
  noticia_id          bigint NOT NULL REFERENCES noticias.noticia ON DELETE CASCADE,
  municipio_id        bigint NOT NULL REFERENCES nucleo.municipio,
  origem              text NOT NULL REFERENCES nucleo.ref_origem_preenchimento,
  modelo_llm          text,
  validado_por_humano boolean NOT NULL DEFAULT false,
  validado_em         timestamptz,
  lote_carga_id       bigint NOT NULL REFERENCES nucleo.lote_carga,
  PRIMARY KEY (noticia_id, municipio_id),
  CHECK (origem = 'llm' OR modelo_llm IS NULL),
  CHECK (validado_por_humano = (validado_em IS NOT NULL))
);
COMMENT ON TABLE noticias.noticia_municipio IS 'Municípios mencionados como local dos fatos da notícia.';

-- ---------------------------------------------------------------------------
-- Eixo 2: pessoas envolvidas
-- ---------------------------------------------------------------------------

CREATE TABLE noticias.noticia_pessoa (
  noticia_id          bigint NOT NULL REFERENCES noticias.noticia ON DELETE CASCADE,
  pessoa_id           bigint NOT NULL REFERENCES nucleo.pessoa,
  papel               text NOT NULL REFERENCES noticias.ref_papel_pessoa,
  origem              text NOT NULL REFERENCES nucleo.ref_origem_preenchimento,
  modelo_llm          text,
  validado_por_humano boolean NOT NULL DEFAULT false,
  validado_em         timestamptz,
  lote_carga_id       bigint NOT NULL REFERENCES nucleo.lote_carga,
  PRIMARY KEY (noticia_id, pessoa_id, papel),
  CHECK (origem = 'llm' OR modelo_llm IS NULL),
  CHECK (validado_por_humano = (validado_em IS NOT NULL))
);
COMMENT ON TABLE noticias.noticia_pessoa IS 'Eixo 2 (pessoas envolvidas): pessoa citada na notícia e seu papel.';
CREATE INDEX ON noticias.noticia_pessoa (pessoa_id);

-- ---------------------------------------------------------------------------
-- Eixo 3: homicídio
-- ---------------------------------------------------------------------------

CREATE TABLE noticias.homicidio_noticiado (
  id                  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  noticia_id          bigint NOT NULL REFERENCES noticias.noticia ON DELETE CASCADE,
  municipio_id        bigint REFERENCES nucleo.municipio,
  data_fato           date,
  qtd_vitimas         integer NOT NULL CHECK (qtd_vitimas >= 1),
  meio_empregado      text,
  motivacao           text,
  origem              text NOT NULL REFERENCES nucleo.ref_origem_preenchimento,
  modelo_llm          text,
  validado_por_humano boolean NOT NULL DEFAULT false,
  validado_em         timestamptz,
  lote_carga_id       bigint NOT NULL REFERENCES nucleo.lote_carga,
  CHECK (origem = 'llm' OR modelo_llm IS NULL),
  CHECK (validado_por_humano = (validado_em IS NOT NULL))
);
COMMENT ON TABLE noticias.homicidio_noticiado IS 'Eixo 3 (homicídio): evento de homicídio relatado na notícia.';
CREATE INDEX ON noticias.homicidio_noticiado (noticia_id);
CREATE INDEX ON noticias.homicidio_noticiado (municipio_id);

-- ---------------------------------------------------------------------------
-- Eixo 4: gestão e estrutura faccional
-- ---------------------------------------------------------------------------

CREATE TABLE noticias.estrutura_faccional (
  id                  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  noticia_id          bigint NOT NULL REFERENCES noticias.noticia ON DELETE CASCADE,
  faccao_id           bigint NOT NULL REFERENCES nucleo.faccao,
  pessoa_id           bigint REFERENCES nucleo.pessoa,
  cargo_funcao        text,
  descricao           text,
  origem              text NOT NULL REFERENCES nucleo.ref_origem_preenchimento,
  modelo_llm          text,
  validado_por_humano boolean NOT NULL DEFAULT false,
  validado_em         timestamptz,
  lote_carga_id       bigint NOT NULL REFERENCES nucleo.lote_carga,
  CHECK (origem = 'llm' OR modelo_llm IS NULL),
  CHECK (validado_por_humano = (validado_em IS NOT NULL))
);
COMMENT ON TABLE noticias.estrutura_faccional IS 'Eixo 4 (gestão e estrutura faccional): posição/função de uma pessoa ou traço organizacional de uma facção.';
CREATE INDEX ON noticias.estrutura_faccional (noticia_id);
CREATE INDEX ON noticias.estrutura_faccional (faccao_id);

-- ---------------------------------------------------------------------------
-- Eixo 5: disputas territoriais
-- ---------------------------------------------------------------------------

CREATE TABLE noticias.disputa_territorial (
  id                  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  noticia_id          bigint NOT NULL REFERENCES noticias.noticia ON DELETE CASCADE,
  municipio_id        bigint REFERENCES nucleo.municipio,
  territorio          text NOT NULL,
  descricao           text,
  origem              text NOT NULL REFERENCES nucleo.ref_origem_preenchimento,
  modelo_llm          text,
  validado_por_humano boolean NOT NULL DEFAULT false,
  validado_em         timestamptz,
  lote_carga_id       bigint NOT NULL REFERENCES nucleo.lote_carga,
  CHECK (origem = 'llm' OR modelo_llm IS NULL),
  CHECK (validado_por_humano = (validado_em IS NOT NULL))
);
COMMENT ON TABLE noticias.disputa_territorial IS 'Eixo 5 (disputas territoriais): disputa por um território relatada na notícia.';
CREATE INDEX ON noticias.disputa_territorial (noticia_id);
CREATE INDEX ON noticias.disputa_territorial (municipio_id);

CREATE TABLE noticias.disputa_faccao (
  disputa_id bigint NOT NULL REFERENCES noticias.disputa_territorial ON DELETE CASCADE,
  faccao_id  bigint NOT NULL REFERENCES nucleo.faccao,
  PRIMARY KEY (disputa_id, faccao_id)
);
COMMENT ON TABLE noticias.disputa_faccao IS 'Facções envolvidas em cada disputa territorial.';
CREATE INDEX ON noticias.disputa_faccao (faccao_id);

-- ---------------------------------------------------------------------------
-- Eixo 6: confrontos e alianças
-- ---------------------------------------------------------------------------

CREATE TABLE noticias.relacao_faccional (
  id                  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  noticia_id          bigint NOT NULL REFERENCES noticias.noticia ON DELETE CASCADE,
  faccao_a_id         bigint NOT NULL REFERENCES nucleo.faccao,
  faccao_b_id         bigint NOT NULL REFERENCES nucleo.faccao,
  tipo                text NOT NULL REFERENCES noticias.ref_tipo_relacao,
  descricao           text,
  origem              text NOT NULL REFERENCES nucleo.ref_origem_preenchimento,
  modelo_llm          text,
  validado_por_humano boolean NOT NULL DEFAULT false,
  validado_em         timestamptz,
  lote_carga_id       bigint NOT NULL REFERENCES nucleo.lote_carga,
  CHECK (faccao_a_id <> faccao_b_id),
  CHECK (origem = 'llm' OR modelo_llm IS NULL),
  CHECK (validado_por_humano = (validado_em IS NOT NULL))
);
COMMENT ON TABLE noticias.relacao_faccional IS 'Eixo 6 (confrontos e alianças): relação entre duas facções relatada na notícia.';
CREATE INDEX ON noticias.relacao_faccional (noticia_id);
CREATE INDEX ON noticias.relacao_faccional (faccao_a_id);
CREATE INDEX ON noticias.relacao_faccional (faccao_b_id);

-- ---------------------------------------------------------------------------
-- Eixo 7: lavagem de dinheiro
-- ---------------------------------------------------------------------------

CREATE TABLE noticias.lavagem_dinheiro (
  id                  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  noticia_id          bigint NOT NULL REFERENCES noticias.noticia ON DELETE CASCADE,
  faccao_id           bigint REFERENCES nucleo.faccao,
  mecanismo           text NOT NULL,
  valor_estimado      numeric(18,2) CHECK (valor_estimado >= 0),
  descricao           text,
  origem              text NOT NULL REFERENCES nucleo.ref_origem_preenchimento,
  modelo_llm          text,
  validado_por_humano boolean NOT NULL DEFAULT false,
  validado_em         timestamptz,
  lote_carga_id       bigint NOT NULL REFERENCES nucleo.lote_carga,
  CHECK (origem = 'llm' OR modelo_llm IS NULL),
  CHECK (validado_por_humano = (validado_em IS NOT NULL))
);
COMMENT ON TABLE noticias.lavagem_dinheiro IS 'Eixo 7 (lavagem de dinheiro): esquema de lavagem relatado na notícia.';
CREATE INDEX ON noticias.lavagem_dinheiro (noticia_id);

-- ---------------------------------------------------------------------------
-- Eixo 8: atividades econômicas ilícitas
-- ---------------------------------------------------------------------------

CREATE TABLE noticias.atividade_ilicita (
  id                  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  noticia_id          bigint NOT NULL REFERENCES noticias.noticia ON DELETE CASCADE,
  faccao_id           bigint REFERENCES nucleo.faccao,
  tipo                text NOT NULL REFERENCES noticias.ref_tipo_atividade,
  descricao           text,
  origem              text NOT NULL REFERENCES nucleo.ref_origem_preenchimento,
  modelo_llm          text,
  validado_por_humano boolean NOT NULL DEFAULT false,
  validado_em         timestamptz,
  lote_carga_id       bigint NOT NULL REFERENCES nucleo.lote_carga,
  CHECK (origem = 'llm' OR modelo_llm IS NULL),
  CHECK (validado_por_humano = (validado_em IS NOT NULL))
);
COMMENT ON TABLE noticias.atividade_ilicita IS 'Eixo 8 (atividades econômicas ilícitas): atividade ilícita relatada na notícia.';
CREATE INDEX ON noticias.atividade_ilicita (noticia_id);
CREATE INDEX ON noticias.atividade_ilicita (tipo);

-- ---------------------------------------------------------------------------
-- Eixo 9: atuação política
-- ---------------------------------------------------------------------------

CREATE TABLE noticias.atuacao_politica (
  id                  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  noticia_id          bigint NOT NULL REFERENCES noticias.noticia ON DELETE CASCADE,
  faccao_id           bigint REFERENCES nucleo.faccao,
  pessoa_id           bigint REFERENCES nucleo.pessoa,
  cargo               text,
  descricao           text NOT NULL,
  origem              text NOT NULL REFERENCES nucleo.ref_origem_preenchimento,
  modelo_llm          text,
  validado_por_humano boolean NOT NULL DEFAULT false,
  validado_em         timestamptz,
  lote_carga_id       bigint NOT NULL REFERENCES nucleo.lote_carga,
  CHECK (origem = 'llm' OR modelo_llm IS NULL),
  CHECK (validado_por_humano = (validado_em IS NOT NULL))
);
COMMENT ON TABLE noticias.atuacao_politica IS 'Eixo 9 (atuação política): vínculo ou ação política de facção ou pessoa relatada na notícia.';
CREATE INDEX ON noticias.atuacao_politica (noticia_id);

-- ---------------------------------------------------------------------------
-- Eixo 11: operações policiais (antes de apreensão, que a referencia)
-- ---------------------------------------------------------------------------

CREATE TABLE noticias.operacao_policial (
  id                  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  noticia_id          bigint NOT NULL REFERENCES noticias.noticia ON DELETE CASCADE,
  codigo_origem       text NOT NULL,
  nome_operacao       text,
  orgao               text,
  municipio_id        bigint REFERENCES nucleo.municipio,
  data_operacao       date,
  qtd_presos          integer CHECK (qtd_presos >= 0),
  qtd_mortos          integer CHECK (qtd_mortos >= 0),
  origem              text NOT NULL REFERENCES nucleo.ref_origem_preenchimento,
  modelo_llm          text,
  validado_por_humano boolean NOT NULL DEFAULT false,
  validado_em         timestamptz,
  lote_carga_id       bigint NOT NULL REFERENCES nucleo.lote_carga,
  UNIQUE (noticia_id, codigo_origem),
  CHECK (origem = 'llm' OR modelo_llm IS NULL),
  CHECK (validado_por_humano = (validado_em IS NOT NULL))
);
COMMENT ON TABLE noticias.operacao_policial IS 'Eixo 11 (operações policiais): operação policial relatada na notícia.';
CREATE INDEX ON noticias.operacao_policial (municipio_id);

-- ---------------------------------------------------------------------------
-- Eixo 10: apreensões
-- ---------------------------------------------------------------------------

CREATE TABLE noticias.apreensao (
  id                  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  noticia_id          bigint NOT NULL REFERENCES noticias.noticia ON DELETE CASCADE,
  operacao_id         bigint REFERENCES noticias.operacao_policial,
  municipio_id        bigint REFERENCES nucleo.municipio,
  item                text NOT NULL REFERENCES noticias.ref_tipo_item,
  quantidade          numeric CHECK (quantidade >= 0),
  unidade             text,
  descricao           text,
  origem              text NOT NULL REFERENCES nucleo.ref_origem_preenchimento,
  modelo_llm          text,
  validado_por_humano boolean NOT NULL DEFAULT false,
  validado_em         timestamptz,
  lote_carga_id       bigint NOT NULL REFERENCES nucleo.lote_carga,
  CHECK (quantidade IS NULL OR unidade IS NOT NULL),
  CHECK (origem = 'llm' OR modelo_llm IS NULL),
  CHECK (validado_por_humano = (validado_em IS NOT NULL))
);
COMMENT ON TABLE noticias.apreensao IS 'Eixo 10 (apreensões): item apreendido relatado na notícia.';
CREATE INDEX ON noticias.apreensao (noticia_id);
CREATE INDEX ON noticias.apreensao (operacao_id);
CREATE INDEX ON noticias.apreensao (municipio_id);

-- ---------------------------------------------------------------------------
-- Comentários das colunas repetidas (proveniência e chaves comuns)
-- ---------------------------------------------------------------------------

DO $$
DECLARE
  t text;
  c record;
  comentario text;
BEGIN
  FOR t IN
    SELECT table_name FROM information_schema.tables
    WHERE table_schema = 'noticias' AND table_type = 'BASE TABLE'
  LOOP
    FOR c IN
      SELECT column_name FROM information_schema.columns
      WHERE table_schema = 'noticias' AND table_name = t
    LOOP
      comentario := CASE c.column_name
        WHEN 'origem'              THEN 'Quem preencheu o registro: llm ou humano.'
        WHEN 'modelo_llm'          THEN 'Modelo de linguagem que preencheu o registro (só quando origem = llm).'
        WHEN 'validado_por_humano' THEN 'Se um pesquisador revisou e confirmou o registro.'
        WHEN 'validado_em'         THEN 'Instante da validação humana (preenchido se e só se validado_por_humano).'
        WHEN 'lote_carga_id'       THEN 'Lote de carga que trouxe o registro.'
        WHEN 'noticia_id'          THEN 'Notícia de origem.'
        WHEN 'municipio_id'        THEN 'Município do fato.'
        WHEN 'pessoa_id'           THEN 'Pessoa envolvida.'
        WHEN 'faccao_id'           THEN 'Facção envolvida.'
        WHEN 'id'                  THEN 'Identificador interno.'
        WHEN 'papel'               THEN 'Papel da pessoa na notícia.'
        WHEN 'data_fato'           THEN 'Data do homicídio, se informada.'
        WHEN 'qtd_vitimas'         THEN 'Número de vítimas fatais no evento.'
        WHEN 'meio_empregado'      THEN 'Meio empregado (ex.: arma de fogo).'
        WHEN 'motivacao'           THEN 'Motivação atribuída pela notícia.'
        WHEN 'cargo_funcao'        THEN 'Cargo ou função na estrutura da facção.'
        WHEN 'descricao'           THEN 'Descrição livre extraída da notícia.'
        WHEN 'territorio'          THEN 'Território em disputa (bairro, comunidade, região).'
        WHEN 'disputa_id'          THEN 'Disputa territorial.'
        WHEN 'faccao_a_id'         THEN 'Primeira facção da relação.'
        WHEN 'faccao_b_id'         THEN 'Segunda facção da relação (diferente da primeira).'
        WHEN 'tipo'                THEN 'Tipo, conforme o domínio de referência.'
        WHEN 'mecanismo'           THEN 'Mecanismo de lavagem (ex.: empresa de fachada).'
        WHEN 'valor_estimado'      THEN 'Valor estimado em reais.'
        WHEN 'cargo'               THEN 'Cargo político envolvido.'
        WHEN 'codigo_origem'       THEN 'Identificador no dataset original.'
        WHEN 'nome_operacao'       THEN 'Nome da operação.'
        WHEN 'orgao'               THEN 'Órgão responsável (ex.: PF, PC-RJ).'
        WHEN 'data_operacao'       THEN 'Data da operação.'
        WHEN 'qtd_presos'          THEN 'Número de presos na operação.'
        WHEN 'qtd_mortos'          THEN 'Número de mortos na operação.'
        WHEN 'operacao_id'         THEN 'Operação policial em que houve a apreensão, se houver.'
        WHEN 'item'                THEN 'Tipo de item apreendido.'
        WHEN 'quantidade'          THEN 'Quantidade apreendida.'
        WHEN 'unidade'             THEN 'Unidade da quantidade (ex.: kg, un).'
        WHEN 'codigo'              THEN 'Código do domínio.'
        ELSE NULL
      END;
      IF comentario IS NOT NULL
         AND col_description(format('noticias.%I', t)::regclass,
               (SELECT attnum FROM pg_attribute
                WHERE attrelid = format('noticias.%I', t)::regclass AND attname = c.column_name)) IS NULL
      THEN
        EXECUTE format('COMMENT ON COLUMN noticias.%I.%I IS %L', t, c.column_name, comentario);
      END IF;
    END LOOP;
  END LOOP;
END $$;
