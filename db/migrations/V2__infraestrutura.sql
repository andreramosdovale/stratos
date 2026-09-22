-- V2: dataset Homicídios × Infraestrutura.
-- Os indicadores de cada eixo ficam num catálogo (indicador) com as medições
-- em formato longo (medicao_indicador): novos indicadores entram sem DDL.

CREATE TABLE infraestrutura.ref_eixo (
  codigo    text PRIMARY KEY,
  descricao text NOT NULL
);
COMMENT ON TABLE infraestrutura.ref_eixo IS 'Domínio: eixos de infraestrutura.';
COMMENT ON COLUMN infraestrutura.ref_eixo.codigo IS 'Código do eixo.';
COMMENT ON COLUMN infraestrutura.ref_eixo.descricao IS 'Descrição do eixo.';
INSERT INTO infraestrutura.ref_eixo VALUES
  ('transportes', 'Transportes'),
  ('telecomunicacoes', 'Telecomunicações'),
  ('energia', 'Energia'),
  ('projetos_financiados', 'Projetos financiados por bancos nacionais ou regionais de desenvolvimento');

CREATE TABLE infraestrutura.homicidio (
  id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  municipio_id   bigint NOT NULL REFERENCES nucleo.municipio,
  ano            smallint NOT NULL CHECK (ano BETWEEN 1979 AND 2100),
  quantidade     integer NOT NULL CHECK (quantidade >= 0),
  fonte_dado_id  bigint NOT NULL REFERENCES nucleo.fonte_dado,
  lote_carga_id  bigint NOT NULL REFERENCES nucleo.lote_carga,
  UNIQUE (municipio_id, ano, fonte_dado_id)
);
COMMENT ON TABLE infraestrutura.homicidio IS 'Contagem anual de homicídios por município e fonte.';
COMMENT ON COLUMN infraestrutura.homicidio.id IS 'Identificador interno.';
COMMENT ON COLUMN infraestrutura.homicidio.municipio_id IS 'Município de ocorrência.';
COMMENT ON COLUMN infraestrutura.homicidio.ano IS 'Ano de referência.';
COMMENT ON COLUMN infraestrutura.homicidio.quantidade IS 'Número de homicídios no ano.';
COMMENT ON COLUMN infraestrutura.homicidio.fonte_dado_id IS 'Fonte da contagem.';
COMMENT ON COLUMN infraestrutura.homicidio.lote_carga_id IS 'Lote de carga que trouxe o registro.';
CREATE INDEX ON infraestrutura.homicidio (ano);

CREATE TABLE infraestrutura.indicador (
  id        bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  codigo    text NOT NULL UNIQUE CHECK (codigo ~ '^[a-z0-9_]+$'),
  eixo      text NOT NULL REFERENCES infraestrutura.ref_eixo,
  nome      text NOT NULL,
  unidade   text NOT NULL,
  descricao text NOT NULL
);
COMMENT ON TABLE infraestrutura.indicador IS 'Catálogo de indicadores de infraestrutura, classificados por eixo.';
COMMENT ON COLUMN infraestrutura.indicador.id IS 'Identificador interno.';
COMMENT ON COLUMN infraestrutura.indicador.codigo IS 'Código estável do indicador (snake_case); chave natural.';
COMMENT ON COLUMN infraestrutura.indicador.eixo IS 'Eixo de infraestrutura.';
COMMENT ON COLUMN infraestrutura.indicador.nome IS 'Nome legível.';
COMMENT ON COLUMN infraestrutura.indicador.unidade IS 'Unidade de medida (ex.: km, %, MWh).';
COMMENT ON COLUMN infraestrutura.indicador.descricao IS 'Definição e forma de cálculo.';

CREATE TABLE infraestrutura.medicao_indicador (
  id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  municipio_id   bigint NOT NULL REFERENCES nucleo.municipio,
  ano            smallint NOT NULL CHECK (ano BETWEEN 1979 AND 2100),
  indicador_id   bigint NOT NULL REFERENCES infraestrutura.indicador,
  valor          numeric NOT NULL,
  fonte_dado_id  bigint NOT NULL REFERENCES nucleo.fonte_dado,
  lote_carga_id  bigint NOT NULL REFERENCES nucleo.lote_carga,
  UNIQUE (municipio_id, ano, indicador_id, fonte_dado_id)
);
COMMENT ON TABLE infraestrutura.medicao_indicador IS 'Valor de um indicador de infraestrutura para um município e ano.';
COMMENT ON COLUMN infraestrutura.medicao_indicador.id IS 'Identificador interno.';
COMMENT ON COLUMN infraestrutura.medicao_indicador.municipio_id IS 'Município medido.';
COMMENT ON COLUMN infraestrutura.medicao_indicador.ano IS 'Ano de referência.';
COMMENT ON COLUMN infraestrutura.medicao_indicador.indicador_id IS 'Indicador medido.';
COMMENT ON COLUMN infraestrutura.medicao_indicador.valor IS 'Valor na unidade do indicador.';
COMMENT ON COLUMN infraestrutura.medicao_indicador.fonte_dado_id IS 'Fonte do valor.';
COMMENT ON COLUMN infraestrutura.medicao_indicador.lote_carga_id IS 'Lote de carga que trouxe o registro.';
CREATE INDEX ON infraestrutura.medicao_indicador (indicador_id, ano);

CREATE TABLE infraestrutura.ref_abrangencia_banco (
  codigo    text PRIMARY KEY,
  descricao text NOT NULL
);
COMMENT ON TABLE infraestrutura.ref_abrangencia_banco IS 'Domínio: abrangência de um banco de desenvolvimento.';
COMMENT ON COLUMN infraestrutura.ref_abrangencia_banco.codigo IS 'Código da abrangência.';
COMMENT ON COLUMN infraestrutura.ref_abrangencia_banco.descricao IS 'Descrição.';
INSERT INTO infraestrutura.ref_abrangencia_banco VALUES
  ('nacional', 'Banco nacional de desenvolvimento'),
  ('regional', 'Banco regional de desenvolvimento');

CREATE TABLE infraestrutura.banco_desenvolvimento (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  sigla       text NOT NULL UNIQUE,
  nome        text NOT NULL,
  abrangencia text NOT NULL REFERENCES infraestrutura.ref_abrangencia_banco
);
COMMENT ON TABLE infraestrutura.banco_desenvolvimento IS 'Bancos nacionais ou regionais de desenvolvimento financiadores.';
COMMENT ON COLUMN infraestrutura.banco_desenvolvimento.id IS 'Identificador interno.';
COMMENT ON COLUMN infraestrutura.banco_desenvolvimento.sigla IS 'Sigla do banco; chave natural.';
COMMENT ON COLUMN infraestrutura.banco_desenvolvimento.nome IS 'Nome do banco.';
COMMENT ON COLUMN infraestrutura.banco_desenvolvimento.abrangencia IS 'Nacional ou regional.';

CREATE TABLE infraestrutura.projeto_financiado (
  id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  codigo_origem    text NOT NULL,
  banco_id         bigint NOT NULL REFERENCES infraestrutura.banco_desenvolvimento,
  titulo           text NOT NULL,
  eixo             text NOT NULL REFERENCES infraestrutura.ref_eixo,
  valor_contratado numeric(18,2) CHECK (valor_contratado >= 0),
  data_contratacao date,
  situacao         text,
  fonte_dado_id    bigint NOT NULL REFERENCES nucleo.fonte_dado,
  lote_carga_id    bigint NOT NULL REFERENCES nucleo.lote_carga,
  UNIQUE (banco_id, codigo_origem)
);
COMMENT ON TABLE infraestrutura.projeto_financiado IS 'Projeto de infraestrutura financiado por banco de desenvolvimento.';
COMMENT ON COLUMN infraestrutura.projeto_financiado.id IS 'Identificador interno.';
COMMENT ON COLUMN infraestrutura.projeto_financiado.codigo_origem IS 'Identificador do projeto no banco financiador.';
COMMENT ON COLUMN infraestrutura.projeto_financiado.banco_id IS 'Banco financiador.';
COMMENT ON COLUMN infraestrutura.projeto_financiado.titulo IS 'Título/descrição do projeto.';
COMMENT ON COLUMN infraestrutura.projeto_financiado.eixo IS 'Eixo de infraestrutura do projeto.';
COMMENT ON COLUMN infraestrutura.projeto_financiado.valor_contratado IS 'Valor contratado em reais.';
COMMENT ON COLUMN infraestrutura.projeto_financiado.data_contratacao IS 'Data de contratação.';
COMMENT ON COLUMN infraestrutura.projeto_financiado.situacao IS 'Situação do projeto na fonte (ex.: em execução, concluído).';
COMMENT ON COLUMN infraestrutura.projeto_financiado.fonte_dado_id IS 'Fonte do registro.';
COMMENT ON COLUMN infraestrutura.projeto_financiado.lote_carga_id IS 'Lote de carga que trouxe o registro.';

-- Um projeto pode atender vários municípios (dependência multivalorada isolada: 4FN).
CREATE TABLE infraestrutura.projeto_municipio (
  projeto_id   bigint NOT NULL REFERENCES infraestrutura.projeto_financiado ON DELETE CASCADE,
  municipio_id bigint NOT NULL REFERENCES nucleo.municipio,
  PRIMARY KEY (projeto_id, municipio_id)
);
COMMENT ON TABLE infraestrutura.projeto_municipio IS 'Municípios atendidos por cada projeto financiado.';
COMMENT ON COLUMN infraestrutura.projeto_municipio.projeto_id IS 'Projeto financiado.';
COMMENT ON COLUMN infraestrutura.projeto_municipio.municipio_id IS 'Município atendido.';
CREATE INDEX ON infraestrutura.projeto_municipio (municipio_id);
