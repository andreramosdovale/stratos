-- noticias: CSVs -> staging (um arquivo por eixo; ver README.md)

SELECT pg_temp.criar_staging('noticias', ARRAY['id_noticia', 'veiculo', 'url', 'titulo', 'data_publicacao', 'resumo']);
\copy staging.noticias (id_noticia, veiculo, url, titulo, data_publicacao, resumo) FROM 'noticias.csv' WITH (FORMAT csv, HEADER match, ENCODING 'UTF8')
SELECT pg_temp.limpar('noticias');

SELECT pg_temp.criar_staging('noticia_municipios', ARRAY['id_noticia', 'codigo_ibge', 'origem', 'modelo_llm', 'validado_por_humano', 'validado_em']);
\copy staging.noticia_municipios (id_noticia, codigo_ibge, origem, modelo_llm, validado_por_humano, validado_em) FROM 'noticia_municipios.csv' WITH (FORMAT csv, HEADER match, ENCODING 'UTF8')
SELECT pg_temp.limpar('noticia_municipios');

SELECT pg_temp.criar_staging('noticia_pessoas', ARRAY['id_noticia', 'pessoa_chave', 'pessoa_nome', 'papel', 'origem', 'modelo_llm', 'validado_por_humano', 'validado_em']);
\copy staging.noticia_pessoas (id_noticia, pessoa_chave, pessoa_nome, papel, origem, modelo_llm, validado_por_humano, validado_em) FROM 'noticia_pessoas.csv' WITH (FORMAT csv, HEADER match, ENCODING 'UTF8')
SELECT pg_temp.limpar('noticia_pessoas');

SELECT pg_temp.criar_staging('homicidios_noticiados', ARRAY['id_noticia', 'codigo_ibge', 'data_fato', 'qtd_vitimas', 'meio_empregado', 'motivacao', 'origem', 'modelo_llm', 'validado_por_humano', 'validado_em']);
\copy staging.homicidios_noticiados (id_noticia, codigo_ibge, data_fato, qtd_vitimas, meio_empregado, motivacao, origem, modelo_llm, validado_por_humano, validado_em) FROM 'homicidios_noticiados.csv' WITH (FORMAT csv, HEADER match, ENCODING 'UTF8')
SELECT pg_temp.limpar('homicidios_noticiados');

SELECT pg_temp.criar_staging('estrutura_faccional', ARRAY['id_noticia', 'faccao', 'pessoa_chave', 'pessoa_nome', 'cargo_funcao', 'descricao', 'origem', 'modelo_llm', 'validado_por_humano', 'validado_em']);
\copy staging.estrutura_faccional (id_noticia, faccao, pessoa_chave, pessoa_nome, cargo_funcao, descricao, origem, modelo_llm, validado_por_humano, validado_em) FROM 'estrutura_faccional.csv' WITH (FORMAT csv, HEADER match, ENCODING 'UTF8')
SELECT pg_temp.limpar('estrutura_faccional');

SELECT pg_temp.criar_staging('disputas_territoriais', ARRAY['id_noticia', 'codigo_ibge', 'territorio', 'faccoes', 'descricao', 'origem', 'modelo_llm', 'validado_por_humano', 'validado_em']);
\copy staging.disputas_territoriais (id_noticia, codigo_ibge, territorio, faccoes, descricao, origem, modelo_llm, validado_por_humano, validado_em) FROM 'disputas_territoriais.csv' WITH (FORMAT csv, HEADER match, ENCODING 'UTF8')
SELECT pg_temp.limpar('disputas_territoriais');

SELECT pg_temp.criar_staging('relacoes_faccionais', ARRAY['id_noticia', 'faccao_a', 'faccao_b', 'tipo', 'descricao', 'origem', 'modelo_llm', 'validado_por_humano', 'validado_em']);
\copy staging.relacoes_faccionais (id_noticia, faccao_a, faccao_b, tipo, descricao, origem, modelo_llm, validado_por_humano, validado_em) FROM 'relacoes_faccionais.csv' WITH (FORMAT csv, HEADER match, ENCODING 'UTF8')
SELECT pg_temp.limpar('relacoes_faccionais');

SELECT pg_temp.criar_staging('lavagem_dinheiro', ARRAY['id_noticia', 'faccao', 'mecanismo', 'valor_estimado', 'descricao', 'origem', 'modelo_llm', 'validado_por_humano', 'validado_em']);
\copy staging.lavagem_dinheiro (id_noticia, faccao, mecanismo, valor_estimado, descricao, origem, modelo_llm, validado_por_humano, validado_em) FROM 'lavagem_dinheiro.csv' WITH (FORMAT csv, HEADER match, ENCODING 'UTF8')
SELECT pg_temp.limpar('lavagem_dinheiro');

SELECT pg_temp.criar_staging('atividades_ilicitas', ARRAY['id_noticia', 'faccao', 'tipo', 'descricao', 'origem', 'modelo_llm', 'validado_por_humano', 'validado_em']);
\copy staging.atividades_ilicitas (id_noticia, faccao, tipo, descricao, origem, modelo_llm, validado_por_humano, validado_em) FROM 'atividades_ilicitas.csv' WITH (FORMAT csv, HEADER match, ENCODING 'UTF8')
SELECT pg_temp.limpar('atividades_ilicitas');

SELECT pg_temp.criar_staging('atuacao_politica', ARRAY['id_noticia', 'faccao', 'pessoa_chave', 'pessoa_nome', 'cargo', 'descricao', 'origem', 'modelo_llm', 'validado_por_humano', 'validado_em']);
\copy staging.atuacao_politica (id_noticia, faccao, pessoa_chave, pessoa_nome, cargo, descricao, origem, modelo_llm, validado_por_humano, validado_em) FROM 'atuacao_politica.csv' WITH (FORMAT csv, HEADER match, ENCODING 'UTF8')
SELECT pg_temp.limpar('atuacao_politica');

SELECT pg_temp.criar_staging('operacoes_policiais', ARRAY['id_noticia', 'id_operacao', 'nome_operacao', 'orgao', 'codigo_ibge', 'data_operacao', 'qtd_presos', 'qtd_mortos', 'origem', 'modelo_llm', 'validado_por_humano', 'validado_em']);
\copy staging.operacoes_policiais (id_noticia, id_operacao, nome_operacao, orgao, codigo_ibge, data_operacao, qtd_presos, qtd_mortos, origem, modelo_llm, validado_por_humano, validado_em) FROM 'operacoes_policiais.csv' WITH (FORMAT csv, HEADER match, ENCODING 'UTF8')
SELECT pg_temp.limpar('operacoes_policiais');

SELECT pg_temp.criar_staging('apreensoes', ARRAY['id_noticia', 'id_operacao', 'codigo_ibge', 'item', 'quantidade', 'unidade', 'descricao', 'origem', 'modelo_llm', 'validado_por_humano', 'validado_em']);
\copy staging.apreensoes (id_noticia, id_operacao, codigo_ibge, item, quantidade, unidade, descricao, origem, modelo_llm, validado_por_humano, validado_em) FROM 'apreensoes.csv' WITH (FORMAT csv, HEADER match, ENCODING 'UTF8')
SELECT pg_temp.limpar('apreensoes');
