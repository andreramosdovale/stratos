-- infraestrutura: validação. Acumula rejeições e aborta se houver alguma.
SELECT pg_temp.exigir_carregado('nucleo');

\set ref_municipio 'SELECT codigo_ibge::text FROM nucleo.municipio'
\set ref_fonte 'SELECT nome FROM nucleo.fonte_dado'
\set ano_fora 'CASE WHEN pg_input_is_valid(ano, ''smallint'') THEN ano::smallint NOT BETWEEN 1979 AND 2100 ELSE false END'

-- homicidios.csv
SELECT pg_temp.checar_obrigatorio('homicidios', 'codigo_ibge', 'ano', 'quantidade', 'fonte');
SELECT pg_temp.checar_tipo('homicidios', 'ano', 'smallint');
SELECT pg_temp.checar('homicidios', :'ano_fora', $m$'ano fora de 1979–2100: ' || ano$m$);
SELECT pg_temp.checar_tipo('homicidios', 'quantidade', 'integer');
SELECT pg_temp.checar('homicidios',
  $c$CASE WHEN pg_input_is_valid(quantidade, 'integer') THEN quantidade::integer < 0 ELSE false END$c$,
  $m$'quantidade negativa: ' || quantidade$m$);
SELECT pg_temp.checar_ref('homicidios', 'codigo_ibge', :'ref_municipio', 'nucleo.municipio');
SELECT pg_temp.checar_ref('homicidios', 'fonte', :'ref_fonte', 'nucleo.fonte_dado');
SELECT pg_temp.checar_unico('homicidios', 'codigo_ibge, ano, fonte');

-- indicadores.csv
SELECT pg_temp.checar_obrigatorio('indicadores', 'codigo', 'eixo', 'nome', 'unidade', 'descricao');
SELECT pg_temp.checar('indicadores', $c$codigo !~ '^[a-z0-9_]+$'$c$,
  $m$'codigo deve ser snake_case: ' || codigo$m$);
SELECT pg_temp.checar_ref('indicadores', 'eixo', 'SELECT codigo FROM infraestrutura.ref_eixo', 'infraestrutura.ref_eixo');
SELECT pg_temp.checar_unico('indicadores', 'codigo');

-- medicoes.csv
SELECT pg_temp.checar_obrigatorio('medicoes', 'codigo_ibge', 'ano', 'indicador', 'valor', 'fonte');
SELECT pg_temp.checar_tipo('medicoes', 'ano', 'smallint');
SELECT pg_temp.checar('medicoes', :'ano_fora', $m$'ano fora de 1979–2100: ' || ano$m$);
SELECT pg_temp.checar_tipo('medicoes', 'valor', 'numeric');
SELECT pg_temp.checar_ref('medicoes', 'codigo_ibge', :'ref_municipio', 'nucleo.municipio');
SELECT pg_temp.checar_ref('medicoes', 'indicador', 'SELECT codigo FROM staging.indicadores', 'indicadores.csv');
SELECT pg_temp.checar_ref('medicoes', 'fonte', :'ref_fonte', 'nucleo.fonte_dado');
SELECT pg_temp.checar_unico('medicoes', 'codigo_ibge, ano, indicador, fonte');

-- bancos.csv
SELECT pg_temp.checar_obrigatorio('bancos', 'sigla', 'nome', 'abrangencia');
SELECT pg_temp.checar_ref('bancos', 'abrangencia',
  'SELECT codigo FROM infraestrutura.ref_abrangencia_banco', 'infraestrutura.ref_abrangencia_banco');
SELECT pg_temp.checar_unico('bancos', 'sigla');

-- projetos.csv
SELECT pg_temp.checar_obrigatorio('projetos', 'banco', 'codigo_origem', 'titulo', 'eixo', 'fonte');
SELECT pg_temp.checar_ref('projetos', 'banco', 'SELECT sigla FROM staging.bancos', 'bancos.csv');
SELECT pg_temp.checar_ref('projetos', 'eixo', 'SELECT codigo FROM infraestrutura.ref_eixo', 'infraestrutura.ref_eixo');
SELECT pg_temp.checar_tipo('projetos', 'valor_contratado', 'numeric(18,2)');
SELECT pg_temp.checar('projetos',
  $c$CASE WHEN pg_input_is_valid(valor_contratado, 'numeric') THEN valor_contratado::numeric < 0 ELSE false END$c$,
  $m$'valor_contratado negativo: ' || valor_contratado$m$);
SELECT pg_temp.checar_tipo('projetos', 'data_contratacao', 'date');
SELECT pg_temp.checar_ref('projetos', 'fonte', :'ref_fonte', 'nucleo.fonte_dado');
SELECT pg_temp.checar_ref_lista('projetos', 'municipios', :'ref_municipio', 'nucleo.municipio');
SELECT pg_temp.checar_unico('projetos', 'banco, codigo_origem');

\ir ../comum/relatorio_rejeicoes.sql
