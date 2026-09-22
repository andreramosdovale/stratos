-- infraestrutura: CSVs -> staging
SELECT pg_temp.criar_staging('homicidios', ARRAY['codigo_ibge', 'ano', 'quantidade', 'fonte']);
\copy staging.homicidios (codigo_ibge, ano, quantidade, fonte) FROM 'homicidios.csv' WITH (FORMAT csv, HEADER match, ENCODING 'UTF8')
SELECT pg_temp.limpar('homicidios');

SELECT pg_temp.criar_staging('indicadores', ARRAY['codigo', 'eixo', 'nome', 'unidade', 'descricao']);
\copy staging.indicadores (codigo, eixo, nome, unidade, descricao) FROM 'indicadores.csv' WITH (FORMAT csv, HEADER match, ENCODING 'UTF8')
SELECT pg_temp.limpar('indicadores');

SELECT pg_temp.criar_staging('medicoes', ARRAY['codigo_ibge', 'ano', 'indicador', 'valor', 'fonte']);
\copy staging.medicoes (codigo_ibge, ano, indicador, valor, fonte) FROM 'medicoes.csv' WITH (FORMAT csv, HEADER match, ENCODING 'UTF8')
SELECT pg_temp.limpar('medicoes');

SELECT pg_temp.criar_staging('bancos', ARRAY['sigla', 'nome', 'abrangencia']);
\copy staging.bancos (sigla, nome, abrangencia) FROM 'bancos.csv' WITH (FORMAT csv, HEADER match, ENCODING 'UTF8')
SELECT pg_temp.limpar('bancos');

SELECT pg_temp.criar_staging('projetos', ARRAY['banco', 'codigo_origem', 'titulo', 'eixo',
  'valor_contratado', 'data_contratacao', 'situacao', 'fonte', 'municipios']);
\copy staging.projetos (banco, codigo_origem, titulo, eixo, valor_contratado, data_contratacao, situacao, fonte, municipios) FROM 'projetos.csv' WITH (FORMAT csv, HEADER match, ENCODING 'UTF8')
SELECT pg_temp.limpar('projetos');
