-- nucleo: CSVs -> staging
SELECT pg_temp.criar_staging('municipios', ARRAY['codigo_ibge', 'nome', 'uf']);
\copy staging.municipios (codigo_ibge, nome, uf) FROM 'municipios.csv' WITH (FORMAT csv, HEADER match, ENCODING 'UTF8')
SELECT pg_temp.limpar('municipios');

SELECT pg_temp.criar_staging('fontes', ARRAY['nome', 'descricao', 'url']);
\copy staging.fontes (nome, descricao, url) FROM 'fontes.csv' WITH (FORMAT csv, HEADER match, ENCODING 'UTF8')
SELECT pg_temp.limpar('fontes');
