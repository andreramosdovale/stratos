-- Entidades compartilhadas (nucleo).

-- ---------------------------------------------------------------------------
-- Domínios fechados (tabelas de referência, evoluem sem DDL)
-- ---------------------------------------------------------------------------

CREATE TABLE nucleo.ref_origem_preenchimento (
  codigo    text PRIMARY KEY,
  descricao text NOT NULL
);
COMMENT ON TABLE nucleo.ref_origem_preenchimento IS 'Domínio: quem preencheu um campo informacional (LLM ou humano).';
COMMENT ON COLUMN nucleo.ref_origem_preenchimento.codigo IS 'Código do domínio.';
COMMENT ON COLUMN nucleo.ref_origem_preenchimento.descricao IS 'Descrição legível.';
INSERT INTO nucleo.ref_origem_preenchimento VALUES
  ('llm', 'Preenchido por modelo de linguagem'),
  ('humano', 'Preenchido manualmente por pesquisador');

-- ---------------------------------------------------------------------------
-- Localidades
-- ---------------------------------------------------------------------------

CREATE TABLE nucleo.uf (
  id    smallint PRIMARY KEY CHECK (id BETWEEN 11 AND 53),
  sigla char(2) NOT NULL UNIQUE CHECK (sigla ~ '^[A-Z]{2}$'),
  nome  text NOT NULL UNIQUE
);
COMMENT ON TABLE nucleo.uf IS 'Unidades da Federação (código IBGE).';
COMMENT ON COLUMN nucleo.uf.id IS 'Código IBGE da UF (2 dígitos).';
COMMENT ON COLUMN nucleo.uf.sigla IS 'Sigla da UF.';
COMMENT ON COLUMN nucleo.uf.nome IS 'Nome da UF.';
INSERT INTO nucleo.uf (id, sigla, nome) VALUES
  (11,'RO','Rondônia'),(12,'AC','Acre'),(13,'AM','Amazonas'),(14,'RR','Roraima'),
  (15,'PA','Pará'),(16,'AP','Amapá'),(17,'TO','Tocantins'),(21,'MA','Maranhão'),
  (22,'PI','Piauí'),(23,'CE','Ceará'),(24,'RN','Rio Grande do Norte'),(25,'PB','Paraíba'),
  (26,'PE','Pernambuco'),(27,'AL','Alagoas'),(28,'SE','Sergipe'),(29,'BA','Bahia'),
  (31,'MG','Minas Gerais'),(32,'ES','Espírito Santo'),(33,'RJ','Rio de Janeiro'),
  (35,'SP','São Paulo'),(41,'PR','Paraná'),(42,'SC','Santa Catarina'),
  (43,'RS','Rio Grande do Sul'),(50,'MS','Mato Grosso do Sul'),(51,'MT','Mato Grosso'),
  (52,'GO','Goiás'),(53,'DF','Distrito Federal');

CREATE TABLE nucleo.municipio (
  id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  codigo_ibge  integer NOT NULL UNIQUE CHECK (codigo_ibge BETWEEN 1100000 AND 5399999),
  nome         text NOT NULL,
  uf_id        smallint NOT NULL REFERENCES nucleo.uf,
  criado_em    timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now(),
  CHECK (codigo_ibge / 100000 = uf_id)
);
COMMENT ON TABLE nucleo.municipio IS 'Municípios brasileiros; localidade comum aos datasets.';
COMMENT ON COLUMN nucleo.municipio.id IS 'Identificador interno.';
COMMENT ON COLUMN nucleo.municipio.codigo_ibge IS 'Código IBGE do município (7 dígitos); chave natural.';
COMMENT ON COLUMN nucleo.municipio.nome IS 'Nome do município.';
COMMENT ON COLUMN nucleo.municipio.uf_id IS 'UF do município; deve coincidir com os 2 primeiros dígitos do código IBGE.';
COMMENT ON COLUMN nucleo.municipio.criado_em IS 'Instante de criação do registro.';
COMMENT ON COLUMN nucleo.municipio.atualizado_em IS 'Instante da última alteração do registro.';
CREATE INDEX ON nucleo.municipio (uf_id);

-- ---------------------------------------------------------------------------
-- Proveniência
-- ---------------------------------------------------------------------------

CREATE TABLE nucleo.fonte_dado (
  id        bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nome      text NOT NULL UNIQUE,
  descricao text,
  url       text
);
COMMENT ON TABLE nucleo.fonte_dado IS 'Fontes primárias dos dados (ex.: SIM/DataSUS, Anatel, ANEEL, BNDES).';
COMMENT ON COLUMN nucleo.fonte_dado.id IS 'Identificador interno.';
COMMENT ON COLUMN nucleo.fonte_dado.nome IS 'Nome curto da fonte; chave natural.';
COMMENT ON COLUMN nucleo.fonte_dado.descricao IS 'Descrição da fonte e da metodologia de coleta.';
COMMENT ON COLUMN nucleo.fonte_dado.url IS 'Endereço de referência da fonte.';

CREATE TABLE nucleo.lote_carga (
  id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  conjunto      text NOT NULL CHECK (conjunto IN ('nucleo', 'infraestrutura', 'noticias')),
  arquivos      jsonb NOT NULL,
  carregado_em  timestamptz NOT NULL DEFAULT now(),
  carregado_por text NOT NULL DEFAULT session_user,
  observacao    text
);
COMMENT ON TABLE nucleo.lote_carga IS 'Cada execução de carga de dados; garante rastreabilidade de cada registro até o arquivo de origem.';
COMMENT ON COLUMN nucleo.lote_carga.id IS 'Identificador do lote.';
COMMENT ON COLUMN nucleo.lote_carga.conjunto IS 'Conjunto carregado (nucleo, infraestrutura, noticias).';
COMMENT ON COLUMN nucleo.lote_carga.arquivos IS 'Mapa arquivo → SHA-256 dos arquivos carregados.';
COMMENT ON COLUMN nucleo.lote_carga.carregado_em IS 'Instante da carga.';
COMMENT ON COLUMN nucleo.lote_carga.carregado_por IS 'Usuário de banco que executou a carga.';
COMMENT ON COLUMN nucleo.lote_carga.observacao IS 'Observação livre do curador.';

-- ---------------------------------------------------------------------------
-- Atores
-- ---------------------------------------------------------------------------

CREATE TABLE nucleo.pessoa (
  id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  chave_origem  text NOT NULL UNIQUE,
  nome          text NOT NULL,
  criado_em     timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE nucleo.pessoa IS 'Pessoas citadas nos datasets. Homônimos são distinguidos pela chave de origem atribuída na curadoria.';
COMMENT ON COLUMN nucleo.pessoa.id IS 'Identificador interno.';
COMMENT ON COLUMN nucleo.pessoa.chave_origem IS 'Chave estável atribuída na curadoria para desambiguar pessoas.';
COMMENT ON COLUMN nucleo.pessoa.nome IS 'Nome como aparece na fonte.';
COMMENT ON COLUMN nucleo.pessoa.criado_em IS 'Instante de criação do registro.';
COMMENT ON COLUMN nucleo.pessoa.atualizado_em IS 'Instante da última alteração do registro.';

CREATE TABLE nucleo.faccao (
  id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nome          text NOT NULL UNIQUE,
  criado_em     timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE nucleo.faccao IS 'Facções/organizações criminosas citadas.';
COMMENT ON COLUMN nucleo.faccao.id IS 'Identificador interno.';
COMMENT ON COLUMN nucleo.faccao.nome IS 'Nome canônico da facção; chave natural.';
COMMENT ON COLUMN nucleo.faccao.criado_em IS 'Instante de criação do registro.';
COMMENT ON COLUMN nucleo.faccao.atualizado_em IS 'Instante da última alteração do registro.';

CREATE TABLE nucleo.veiculo_imprensa (
  id   bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nome text NOT NULL UNIQUE,
  url  text
);
COMMENT ON TABLE nucleo.veiculo_imprensa IS 'Veículos de imprensa que publicaram as notícias.';
COMMENT ON COLUMN nucleo.veiculo_imprensa.id IS 'Identificador interno.';
COMMENT ON COLUMN nucleo.veiculo_imprensa.nome IS 'Nome do veículo; chave natural.';
COMMENT ON COLUMN nucleo.veiculo_imprensa.url IS 'Endereço do veículo.';

-- Mantém atualizado_em em qualquer tabela que tenha a coluna.
CREATE FUNCTION nucleo.tocar_atualizado_em() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  NEW.atualizado_em := now();
  RETURN NEW;
END $$;
COMMENT ON FUNCTION nucleo.tocar_atualizado_em() IS 'Trigger: atualiza a coluna atualizado_em.';

CREATE TRIGGER tocar_atualizado_em BEFORE UPDATE ON nucleo.municipio
  FOR EACH ROW EXECUTE FUNCTION nucleo.tocar_atualizado_em();
CREATE TRIGGER tocar_atualizado_em BEFORE UPDATE ON nucleo.pessoa
  FOR EACH ROW EXECUTE FUNCTION nucleo.tocar_atualizado_em();
CREATE TRIGGER tocar_atualizado_em BEFORE UPDATE ON nucleo.faccao
  FOR EACH ROW EXECUTE FUNCTION nucleo.tocar_atualizado_em();
