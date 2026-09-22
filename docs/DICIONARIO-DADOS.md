# Dicionário de dados

> Extraído de `nucleo.v_dicionario_dados` (descrições vindas dos `COMMENT ON` de `db/init/`). Para a versão sempre atual, consulte a visão no banco.

## infraestrutura.banco_desenvolvimento

Bancos nacionais ou regionais de desenvolvimento financiadores.

| Coluna | Tipo | Nulo | Descrição |
|---|---|---|---|
| `id` | bigint | não | Identificador interno. |
| `sigla` | text | não | Sigla do banco; chave natural. |
| `nome` | text | não | Nome do banco. |
| `abrangencia` | text | não | Nacional ou regional. |
## infraestrutura.homicidio

Contagem anual de homicídios por município e fonte.

| Coluna | Tipo | Nulo | Descrição |
|---|---|---|---|
| `id` | bigint | não | Identificador interno. |
| `municipio_id` | bigint | não | Município de ocorrência. |
| `ano` | smallint | não | Ano de referência. |
| `quantidade` | integer | não | Número de homicídios no ano. |
| `fonte_dado_id` | bigint | não | Fonte da contagem. |
| `lote_carga_id` | bigint | não | Lote de carga que trouxe o registro. |
## infraestrutura.indicador

Catálogo de indicadores de infraestrutura, classificados por eixo.

| Coluna | Tipo | Nulo | Descrição |
|---|---|---|---|
| `id` | bigint | não | Identificador interno. |
| `codigo` | text | não | Código estável do indicador (snake_case); chave natural. |
| `eixo` | text | não | Eixo de infraestrutura. |
| `nome` | text | não | Nome legível. |
| `unidade` | text | não | Unidade de medida (ex.: km, %, MWh). |
| `descricao` | text | não | Definição e forma de cálculo. |
## infraestrutura.medicao_indicador

Valor de um indicador de infraestrutura para um município e ano.

| Coluna | Tipo | Nulo | Descrição |
|---|---|---|---|
| `id` | bigint | não | Identificador interno. |
| `municipio_id` | bigint | não | Município medido. |
| `ano` | smallint | não | Ano de referência. |
| `indicador_id` | bigint | não | Indicador medido. |
| `valor` | numeric | não | Valor na unidade do indicador. |
| `fonte_dado_id` | bigint | não | Fonte do valor. |
| `lote_carga_id` | bigint | não | Lote de carga que trouxe o registro. |
## infraestrutura.projeto_financiado

Projeto de infraestrutura financiado por banco de desenvolvimento.

| Coluna | Tipo | Nulo | Descrição |
|---|---|---|---|
| `id` | bigint | não | Identificador interno. |
| `codigo_origem` | text | não | Identificador do projeto no banco financiador. |
| `banco_id` | bigint | não | Banco financiador. |
| `titulo` | text | não | Título/descrição do projeto. |
| `eixo` | text | não | Eixo de infraestrutura do projeto. |
| `valor_contratado` | numeric(18,2) | sim | Valor contratado em reais. |
| `data_contratacao` | date | sim | Data de contratação. |
| `situacao` | text | sim | Situação do projeto na fonte (ex.: em execução, concluído). |
| `fonte_dado_id` | bigint | não | Fonte do registro. |
| `lote_carga_id` | bigint | não | Lote de carga que trouxe o registro. |
## infraestrutura.projeto_municipio

Municípios atendidos por cada projeto financiado.

| Coluna | Tipo | Nulo | Descrição |
|---|---|---|---|
| `projeto_id` | bigint | não | Projeto financiado. |
| `municipio_id` | bigint | não | Município atendido. |
## infraestrutura.ref_abrangencia_banco

Domínio: abrangência de um banco de desenvolvimento.

| Coluna | Tipo | Nulo | Descrição |
|---|---|---|---|
| `codigo` | text | não | Código da abrangência. |
| `descricao` | text | não | Descrição. |
## infraestrutura.ref_eixo

Domínio: eixos de infraestrutura.

| Coluna | Tipo | Nulo | Descrição |
|---|---|---|---|
| `codigo` | text | não | Código do eixo. |
| `descricao` | text | não | Descrição do eixo. |
## noticias.apreensao

Eixo 10 (apreensões): item apreendido relatado na notícia.

| Coluna | Tipo | Nulo | Descrição |
|---|---|---|---|
| `id` | bigint | não | Identificador interno. |
| `noticia_id` | bigint | não | Notícia de origem. |
| `operacao_id` | bigint | sim | Operação policial em que houve a apreensão, se houver. |
| `municipio_id` | bigint | sim | Município do fato. |
| `item` | text | não | Tipo de item apreendido. |
| `quantidade` | numeric | sim | Quantidade apreendida. |
| `unidade` | text | sim | Unidade da quantidade (ex.: kg, un). |
| `descricao` | text | sim | Descrição livre extraída da notícia. |
| `origem` | text | não | Quem preencheu o registro: llm ou humano. |
| `modelo_llm` | text | sim | Modelo de linguagem que preencheu o registro (só quando origem = llm). |
| `validado_por_humano` | boolean | não | Se um pesquisador revisou e confirmou o registro. |
| `validado_em` | timestamp with time zone | sim | Instante da validação humana (preenchido se e só se validado_por_humano). |
| `lote_carga_id` | bigint | não | Lote de carga que trouxe o registro. |
## noticias.atividade_ilicita

Eixo 8 (atividades econômicas ilícitas): atividade ilícita relatada na notícia.

| Coluna | Tipo | Nulo | Descrição |
|---|---|---|---|
| `id` | bigint | não | Identificador interno. |
| `noticia_id` | bigint | não | Notícia de origem. |
| `faccao_id` | bigint | sim | Facção envolvida. |
| `tipo` | text | não | Tipo, conforme o domínio de referência. |
| `descricao` | text | sim | Descrição livre extraída da notícia. |
| `origem` | text | não | Quem preencheu o registro: llm ou humano. |
| `modelo_llm` | text | sim | Modelo de linguagem que preencheu o registro (só quando origem = llm). |
| `validado_por_humano` | boolean | não | Se um pesquisador revisou e confirmou o registro. |
| `validado_em` | timestamp with time zone | sim | Instante da validação humana (preenchido se e só se validado_por_humano). |
| `lote_carga_id` | bigint | não | Lote de carga que trouxe o registro. |
## noticias.atuacao_politica

Eixo 9 (atuação política): vínculo ou ação política de facção ou pessoa relatada na notícia.

| Coluna | Tipo | Nulo | Descrição |
|---|---|---|---|
| `id` | bigint | não | Identificador interno. |
| `noticia_id` | bigint | não | Notícia de origem. |
| `faccao_id` | bigint | sim | Facção envolvida. |
| `pessoa_id` | bigint | sim | Pessoa envolvida. |
| `cargo` | text | sim | Cargo político envolvido. |
| `descricao` | text | não | Descrição livre extraída da notícia. |
| `origem` | text | não | Quem preencheu o registro: llm ou humano. |
| `modelo_llm` | text | sim | Modelo de linguagem que preencheu o registro (só quando origem = llm). |
| `validado_por_humano` | boolean | não | Se um pesquisador revisou e confirmou o registro. |
| `validado_em` | timestamp with time zone | sim | Instante da validação humana (preenchido se e só se validado_por_humano). |
| `lote_carga_id` | bigint | não | Lote de carga que trouxe o registro. |
## noticias.disputa_faccao

Facções envolvidas em cada disputa territorial.

| Coluna | Tipo | Nulo | Descrição |
|---|---|---|---|
| `disputa_id` | bigint | não | Disputa territorial. |
| `faccao_id` | bigint | não | Facção envolvida. |
## noticias.disputa_territorial

Eixo 5 (disputas territoriais): disputa por um território relatada na notícia.

| Coluna | Tipo | Nulo | Descrição |
|---|---|---|---|
| `id` | bigint | não | Identificador interno. |
| `noticia_id` | bigint | não | Notícia de origem. |
| `municipio_id` | bigint | sim | Município do fato. |
| `territorio` | text | não | Território em disputa (bairro, comunidade, região). |
| `descricao` | text | sim | Descrição livre extraída da notícia. |
| `origem` | text | não | Quem preencheu o registro: llm ou humano. |
| `modelo_llm` | text | sim | Modelo de linguagem que preencheu o registro (só quando origem = llm). |
| `validado_por_humano` | boolean | não | Se um pesquisador revisou e confirmou o registro. |
| `validado_em` | timestamp with time zone | sim | Instante da validação humana (preenchido se e só se validado_por_humano). |
| `lote_carga_id` | bigint | não | Lote de carga que trouxe o registro. |
## noticias.estrutura_faccional

Eixo 4 (gestão e estrutura faccional): posição/função de uma pessoa ou traço organizacional de uma facção.

| Coluna | Tipo | Nulo | Descrição |
|---|---|---|---|
| `id` | bigint | não | Identificador interno. |
| `noticia_id` | bigint | não | Notícia de origem. |
| `faccao_id` | bigint | não | Facção envolvida. |
| `pessoa_id` | bigint | sim | Pessoa envolvida. |
| `cargo_funcao` | text | sim | Cargo ou função na estrutura da facção. |
| `descricao` | text | sim | Descrição livre extraída da notícia. |
| `origem` | text | não | Quem preencheu o registro: llm ou humano. |
| `modelo_llm` | text | sim | Modelo de linguagem que preencheu o registro (só quando origem = llm). |
| `validado_por_humano` | boolean | não | Se um pesquisador revisou e confirmou o registro. |
| `validado_em` | timestamp with time zone | sim | Instante da validação humana (preenchido se e só se validado_por_humano). |
| `lote_carga_id` | bigint | não | Lote de carga que trouxe o registro. |
## noticias.homicidio_noticiado

Eixo 3 (homicídio): evento de homicídio relatado na notícia.

| Coluna | Tipo | Nulo | Descrição |
|---|---|---|---|
| `id` | bigint | não | Identificador interno. |
| `noticia_id` | bigint | não | Notícia de origem. |
| `municipio_id` | bigint | sim | Município do fato. |
| `data_fato` | date | sim | Data do homicídio, se informada. |
| `qtd_vitimas` | integer | não | Número de vítimas fatais no evento. |
| `meio_empregado` | text | sim | Meio empregado (ex.: arma de fogo). |
| `motivacao` | text | sim | Motivação atribuída pela notícia. |
| `origem` | text | não | Quem preencheu o registro: llm ou humano. |
| `modelo_llm` | text | sim | Modelo de linguagem que preencheu o registro (só quando origem = llm). |
| `validado_por_humano` | boolean | não | Se um pesquisador revisou e confirmou o registro. |
| `validado_em` | timestamp with time zone | sim | Instante da validação humana (preenchido se e só se validado_por_humano). |
| `lote_carga_id` | bigint | não | Lote de carga que trouxe o registro. |
## noticias.lavagem_dinheiro

Eixo 7 (lavagem de dinheiro): esquema de lavagem relatado na notícia.

| Coluna | Tipo | Nulo | Descrição |
|---|---|---|---|
| `id` | bigint | não | Identificador interno. |
| `noticia_id` | bigint | não | Notícia de origem. |
| `faccao_id` | bigint | sim | Facção envolvida. |
| `mecanismo` | text | não | Mecanismo de lavagem (ex.: empresa de fachada). |
| `valor_estimado` | numeric(18,2) | sim | Valor estimado em reais. |
| `descricao` | text | sim | Descrição livre extraída da notícia. |
| `origem` | text | não | Quem preencheu o registro: llm ou humano. |
| `modelo_llm` | text | sim | Modelo de linguagem que preencheu o registro (só quando origem = llm). |
| `validado_por_humano` | boolean | não | Se um pesquisador revisou e confirmou o registro. |
| `validado_em` | timestamp with time zone | sim | Instante da validação humana (preenchido se e só se validado_por_humano). |
| `lote_carga_id` | bigint | não | Lote de carga que trouxe o registro. |
## noticias.noticia

Eixo 1 (identificadores básicos): uma notícia publicada.

| Coluna | Tipo | Nulo | Descrição |
|---|---|---|---|
| `id` | bigint | não | Identificador interno. |
| `codigo_origem` | text | não | Identificador da notícia no dataset original. |
| `veiculo_id` | bigint | não | Veículo que publicou. |
| `url` | text | não | Endereço da notícia; chave natural. |
| `titulo` | text | não | Título. |
| `data_publicacao` | date | não | Data de publicação (2015–2023). |
| `resumo` | text | sim | Resumo do conteúdo. |
| `lote_carga_id` | bigint | não | Lote de carga que trouxe o registro. |
| `criado_em` | timestamp with time zone | não | Instante de criação do registro. |
| `atualizado_em` | timestamp with time zone | não | Instante da última alteração do registro. |
## noticias.noticia_municipio

Municípios mencionados como local dos fatos da notícia.

| Coluna | Tipo | Nulo | Descrição |
|---|---|---|---|
| `noticia_id` | bigint | não | Notícia de origem. |
| `municipio_id` | bigint | não | Município do fato. |
| `origem` | text | não | Quem preencheu o registro: llm ou humano. |
| `modelo_llm` | text | sim | Modelo de linguagem que preencheu o registro (só quando origem = llm). |
| `validado_por_humano` | boolean | não | Se um pesquisador revisou e confirmou o registro. |
| `validado_em` | timestamp with time zone | sim | Instante da validação humana (preenchido se e só se validado_por_humano). |
| `lote_carga_id` | bigint | não | Lote de carga que trouxe o registro. |
## noticias.noticia_pessoa

Eixo 2 (pessoas envolvidas): pessoa citada na notícia e seu papel.

| Coluna | Tipo | Nulo | Descrição |
|---|---|---|---|
| `noticia_id` | bigint | não | Notícia de origem. |
| `pessoa_id` | bigint | não | Pessoa envolvida. |
| `papel` | text | não | Papel da pessoa na notícia. |
| `origem` | text | não | Quem preencheu o registro: llm ou humano. |
| `modelo_llm` | text | sim | Modelo de linguagem que preencheu o registro (só quando origem = llm). |
| `validado_por_humano` | boolean | não | Se um pesquisador revisou e confirmou o registro. |
| `validado_em` | timestamp with time zone | sim | Instante da validação humana (preenchido se e só se validado_por_humano). |
| `lote_carga_id` | bigint | não | Lote de carga que trouxe o registro. |
## noticias.operacao_policial

Eixo 11 (operações policiais): operação policial relatada na notícia.

| Coluna | Tipo | Nulo | Descrição |
|---|---|---|---|
| `id` | bigint | não | Identificador interno. |
| `noticia_id` | bigint | não | Notícia de origem. |
| `codigo_origem` | text | não | Identificador no dataset original. |
| `nome_operacao` | text | sim | Nome da operação. |
| `orgao` | text | sim | Órgão responsável (ex.: PF, PC-RJ). |
| `municipio_id` | bigint | sim | Município do fato. |
| `data_operacao` | date | sim | Data da operação. |
| `qtd_presos` | integer | sim | Número de presos na operação. |
| `qtd_mortos` | integer | sim | Número de mortos na operação. |
| `origem` | text | não | Quem preencheu o registro: llm ou humano. |
| `modelo_llm` | text | sim | Modelo de linguagem que preencheu o registro (só quando origem = llm). |
| `validado_por_humano` | boolean | não | Se um pesquisador revisou e confirmou o registro. |
| `validado_em` | timestamp with time zone | sim | Instante da validação humana (preenchido se e só se validado_por_humano). |
| `lote_carga_id` | bigint | não | Lote de carga que trouxe o registro. |
## noticias.ref_papel_pessoa

Domínio: papel de uma pessoa numa notícia.

| Coluna | Tipo | Nulo | Descrição |
|---|---|---|---|
| `codigo` | text | não | Código do papel. |
| `descricao` | text | não | Descrição. |
## noticias.ref_tipo_atividade

Domínio: tipo de atividade econômica ilícita.

| Coluna | Tipo | Nulo | Descrição |
|---|---|---|---|
| `codigo` | text | não | Código do tipo. |
| `descricao` | text | não | Descrição. |
## noticias.ref_tipo_item

Domínio: tipo de item apreendido.

| Coluna | Tipo | Nulo | Descrição |
|---|---|---|---|
| `codigo` | text | não | Código do tipo. |
| `descricao` | text | não | Descrição. |
## noticias.ref_tipo_relacao

Domínio: tipo de relação entre facções.

| Coluna | Tipo | Nulo | Descrição |
|---|---|---|---|
| `codigo` | text | não | Código do tipo. |
| `descricao` | text | não | Descrição. |
## noticias.relacao_faccional

Eixo 6 (confrontos e alianças): relação entre duas facções relatada na notícia.

| Coluna | Tipo | Nulo | Descrição |
|---|---|---|---|
| `id` | bigint | não | Identificador interno. |
| `noticia_id` | bigint | não | Notícia de origem. |
| `faccao_a_id` | bigint | não | Primeira facção da relação. |
| `faccao_b_id` | bigint | não | Segunda facção da relação (diferente da primeira). |
| `tipo` | text | não | Tipo, conforme o domínio de referência. |
| `descricao` | text | sim | Descrição livre extraída da notícia. |
| `origem` | text | não | Quem preencheu o registro: llm ou humano. |
| `modelo_llm` | text | sim | Modelo de linguagem que preencheu o registro (só quando origem = llm). |
| `validado_por_humano` | boolean | não | Se um pesquisador revisou e confirmou o registro. |
| `validado_em` | timestamp with time zone | sim | Instante da validação humana (preenchido se e só se validado_por_humano). |
| `lote_carga_id` | bigint | não | Lote de carga que trouxe o registro. |
## noticias.v_qualidade_por_eixo (visão)

Proporção de registros validados por humanos em cada eixo informacional.

| Coluna | Tipo | Nulo | Descrição |
|---|---|---|---|
| `eixo` | text | sim | Eixo informacional. |
| `total` | bigint | sim | Total de registros no eixo. |
| `por_llm` | bigint | sim | Registros preenchidos por LLM. |
| `validados` | bigint | sim | Registros validados por humano. |
| `pct_validados` | numeric | sim | Percentual validado. |
## nucleo.faccao

Facções/organizações criminosas citadas.

| Coluna | Tipo | Nulo | Descrição |
|---|---|---|---|
| `id` | bigint | não | Identificador interno. |
| `nome` | text | não | Nome canônico da facção; chave natural. |
| `criado_em` | timestamp with time zone | não | Instante de criação do registro. |
| `atualizado_em` | timestamp with time zone | não | Instante da última alteração do registro. |
## nucleo.fonte_dado

Fontes primárias dos dados (ex.: SIM/DataSUS, Anatel, ANEEL, BNDES).

| Coluna | Tipo | Nulo | Descrição |
|---|---|---|---|
| `id` | bigint | não | Identificador interno. |
| `nome` | text | não | Nome curto da fonte; chave natural. |
| `descricao` | text | sim | Descrição da fonte e da metodologia de coleta. |
| `url` | text | sim | Endereço de referência da fonte. |
## nucleo.lote_carga

Cada execução de carga de dados; garante rastreabilidade de cada registro até o arquivo de origem.

| Coluna | Tipo | Nulo | Descrição |
|---|---|---|---|
| `id` | bigint | não | Identificador do lote. |
| `conjunto` | text | não | Conjunto carregado (nucleo, infraestrutura, noticias). |
| `arquivos` | jsonb | não | Mapa arquivo → SHA-256 dos arquivos carregados. |
| `carregado_em` | timestamp with time zone | não | Instante da carga. |
| `carregado_por` | text | não | Usuário de banco que executou a carga. |
| `observacao` | text | sim | Observação livre do curador. |
## nucleo.municipio

Municípios brasileiros; localidade comum aos datasets.

| Coluna | Tipo | Nulo | Descrição |
|---|---|---|---|
| `id` | bigint | não | Identificador interno. |
| `codigo_ibge` | integer | não | Código IBGE do município (7 dígitos); chave natural. |
| `nome` | text | não | Nome do município. |
| `uf_id` | smallint | não | UF do município; deve coincidir com os 2 primeiros dígitos do código IBGE. |
| `criado_em` | timestamp with time zone | não | Instante de criação do registro. |
| `atualizado_em` | timestamp with time zone | não | Instante da última alteração do registro. |
## nucleo.pessoa

Pessoas citadas nos datasets. Homônimos são distinguidos pela chave de origem atribuída na curadoria.

| Coluna | Tipo | Nulo | Descrição |
|---|---|---|---|
| `id` | bigint | não | Identificador interno. |
| `chave_origem` | text | não | Chave estável atribuída na curadoria para desambiguar pessoas. |
| `nome` | text | não | Nome como aparece na fonte. |
| `criado_em` | timestamp with time zone | não | Instante de criação do registro. |
| `atualizado_em` | timestamp with time zone | não | Instante da última alteração do registro. |
## nucleo.ref_origem_preenchimento

Domínio: quem preencheu um campo informacional (LLM ou humano).

| Coluna | Tipo | Nulo | Descrição |
|---|---|---|---|
| `codigo` | text | não | Código do domínio. |
| `descricao` | text | não | Descrição legível. |
## nucleo.uf

Unidades da Federação (código IBGE).

| Coluna | Tipo | Nulo | Descrição |
|---|---|---|---|
| `id` | smallint | não | Código IBGE da UF (2 dígitos). |
| `sigla` | character(2) | não | Sigla da UF. |
| `nome` | text | não | Nome da UF. |
## nucleo.v_dicionario_dados (visão)

Dicionário de dados: tabelas, colunas, tipos e descrições dos esquemas de dados.

| Coluna | Tipo | Nulo | Descrição |
|---|---|---|---|
| `esquema` | name | sim | Esquema. |
| `tabela` | name | sim | Tabela ou visão. |
| `tipo_objeto` | text | sim | tabela ou visão. |
| `descricao_tabela` | text | sim | Descrição da tabela. |
| `posicao` | smallint | sim | Posição da coluna na tabela. |
| `coluna` | name | sim | Nome da coluna. |
| `tipo` | text | sim | Tipo de dado. |
| `aceita_nulo` | boolean | sim | Se a coluna aceita nulo. |
| `descricao_coluna` | text | sim | Descrição da coluna. |
## nucleo.veiculo_imprensa

Veículos de imprensa que publicaram as notícias.

| Coluna | Tipo | Nulo | Descrição |
|---|---|---|---|
| `id` | bigint | não | Identificador interno. |
| `nome` | text | não | Nome do veículo; chave natural. |
| `url` | text | sim | Endereço do veículo. |
