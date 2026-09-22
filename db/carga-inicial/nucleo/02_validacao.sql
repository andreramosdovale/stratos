-- nucleo: validação. Acumula rejeições e aborta se houver alguma.
SELECT pg_temp.checar_obrigatorio('municipios', 'codigo_ibge', 'nome', 'uf');
SELECT pg_temp.checar_tipo('municipios', 'codigo_ibge', 'integer');
SELECT pg_temp.checar('municipios', 'codigo_ibge !~ ''^[1-5][0-9]{6}$''',
  '''codigo_ibge inválido (7 dígitos, começando pelo código da região 1–5): '' || codigo_ibge');
SELECT pg_temp.checar_ref('municipios', 'uf', 'SELECT sigla FROM nucleo.uf', 'nucleo.uf');
SELECT pg_temp.checar('municipios',
  'left(codigo_ibge, 2) <> (SELECT id::text FROM nucleo.uf WHERE sigla = uf)',
  '''codigo_ibge não pertence à UF '' || uf');
SELECT pg_temp.checar_unico('municipios', 'codigo_ibge');

SELECT pg_temp.checar_obrigatorio('fontes', 'nome');
SELECT pg_temp.checar_unico('fontes', 'nome');

\ir ../comum/relatorio_rejeicoes.sql
