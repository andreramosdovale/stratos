# Carga inicial

Scripts que levam os datasets de pesquisa para o banco **uma única vez por
conjunto**. Ficam separados das migrações (`db/migrations/`), que só contêm
estrutura e dados de referência. `docker compose up` nunca dispara uma carga.

## Como executar

```bash
# CSVs reais em ./dados/<conjunto>/ (pasta ignorada pelo git)
docker compose --profile carga run --rm carga nucleo
docker compose --profile carga run --rm carga infraestrutura
docker compose --profile carga run --rm carga noticias
# ou, na ordem, tudo de uma vez:
docker compose --profile carga run --rm carga todos

# Testar com os CSVs fictícios de exemplo:
docker compose --profile carga run --rm carga todos /carga/exemplo
```

> No Git Bash do Windows, exporte `MSYS_NO_PATHCONV=1` antes, senão o
> caminho `/carga/exemplo` é convertido para um caminho do Windows.

A ordem é obrigatória: `nucleo` → `infraestrutura` → `noticias`.

## O que acontece em cada conjunto

Tudo roda como `invips_curador`, numa única transação
(`psql --single-transaction -v ON_ERROR_STOP=1`):

1. `01_staging.sql`: recria as tabelas `staging.<arquivo>` (todas as colunas
   `text`, mais o número da linha) e faz `\copy` dos CSVs. Espaços nas pontas
   são removidos e campos vazios viram `NULL`.
2. `02_validacao.sql`: confere obrigatoriedade, tipos, faixas, domínios,
   referências e duplicidades. Cada problema vira uma linha em
   `pg_temp.rejeicao`. Se houver alguma, o script lista
   `arquivo | linha | motivo` e **aborta: nada é gravado**.
3. `03_transformacao.sql`: registra um `nucleo.lote_carga` (com o SHA-256 de
   cada CSV), insere nos esquemas finais, mostra as contagens e apaga as
   tabelas de staging.

Executar de novo um conjunto já carregado é recusado sem alterar nada.
Correções posteriores são feitas pelo curador com DML, e cada uma fica
registrada em `auditoria.log_alteracao`.

## Formato dos arquivos

- UTF-8 **sem BOM**, separador `,`, aspas `"` quando necessário, cabeçalho na
  primeira linha com exatamente os nomes abaixo (`HEADER match`).
- Datas: `AAAA-MM-DD`. Instantes: ISO 8601 com fuso (`2024-03-01T10:00:00-03:00`).
- Decimais com ponto (`12.5`). Booleanos: `true`/`false`.
- Listas dentro de uma célula: itens separados por `|`.
- Colunas marcadas com * são obrigatórias.

### Colunas de proveniência (todos os arquivos de eixo de notícias)

| Coluna | Descrição |
|---|---|
| `origem`* | `llm` ou `humano` |
| `modelo_llm` | Modelo que preencheu. Só pode ser preenchido se `origem = llm`. |
| `validado_por_humano` | `true`/`false` (vazio = `false`) |
| `validado_em` | Obrigatório se e só se `validado_por_humano = true` |

### `nucleo/`

| Arquivo | Colunas |
|---|---|
| `municipios.csv` | `codigo_ibge`* (7 dígitos), `nome`*, `uf`* (sigla) |
| `fontes.csv` | `nome`* (único), `descricao`, `url` |

### `infraestrutura/`

| Arquivo | Colunas |
|---|---|
| `homicidios.csv` | `codigo_ibge`*, `ano`*, `quantidade`*, `fonte`* (nome em `fontes.csv`) |
| `indicadores.csv` | `codigo`* (snake_case, único), `eixo`* (`transportes`, `telecomunicacoes`, `energia`, `projetos_financiados`), `nome`*, `unidade`*, `descricao`* |
| `medicoes.csv` | `codigo_ibge`*, `ano`*, `indicador`* (código em `indicadores.csv`), `valor`*, `fonte`* |
| `bancos.csv` | `sigla`* (única), `nome`*, `abrangencia`* (`nacional`/`regional`) |
| `projetos.csv` | `banco`* (sigla), `codigo_origem`*, `titulo`*, `eixo`*, `valor_contratado`, `data_contratacao`, `situacao`, `fonte`*, `municipios` (lista de códigos IBGE) |

### `noticias/`

Todos os arquivos, exceto `noticias.csv`, têm `id_noticia`* (que precisa
existir em `noticias.csv`) e terminam com as colunas de proveniência.

| Arquivo | Eixo | Colunas próprias |
|---|---|---|
| `noticias.csv` | 1. Identificadores básicos | `id_noticia`* (único), `veiculo`*, `url`* (única), `titulo`*, `data_publicacao`* (2015–2023), `resumo` |
| `noticia_municipios.csv` | local dos fatos | `codigo_ibge`* |
| `noticia_pessoas.csv` | 2. Pessoas envolvidas | `pessoa_chave`, `pessoa_nome`*, `papel`* (`vitima`, `suspeito`, `preso`, `lideranca`, `agente_publico`, `politico`, `testemunha`, `outro`) |
| `homicidios_noticiados.csv` | 3. Homicídio | `codigo_ibge`, `data_fato`, `qtd_vitimas`* (≥ 1), `meio_empregado`, `motivacao` |
| `estrutura_faccional.csv` | 4. Gestão e estrutura faccional | `faccao`*, `pessoa_chave`, `pessoa_nome`, `cargo_funcao`, `descricao` |
| `disputas_territoriais.csv` | 5. Disputas territoriais | `codigo_ibge`, `territorio`*, `faccoes` (lista), `descricao` |
| `relacoes_faccionais.csv` | 6. Confrontos e alianças | `faccao_a`*, `faccao_b`* (diferente de `faccao_a`), `tipo`* (`confronto`, `alianca`, `ruptura`), `descricao` |
| `lavagem_dinheiro.csv` | 7. Lavagem de dinheiro | `faccao`, `mecanismo`*, `valor_estimado`, `descricao` |
| `atividades_ilicitas.csv` | 8. Atividades econômicas ilícitas | `faccao`, `tipo`* (ver `noticias.ref_tipo_atividade`), `descricao` |
| `atuacao_politica.csv` | 9. Atuação política | `faccao`, `pessoa_chave`, `pessoa_nome`, `cargo`, `descricao`* |
| `apreensoes.csv` | 10. Apreensões | `id_operacao` (de `operacoes_policiais.csv`, mesma notícia), `codigo_ibge`, `item`* (`droga`, `arma`, `municao`, `dinheiro`, `veiculo`, `outro`), `quantidade`, `unidade` (obrigatória com quantidade), `descricao` |
| `operacoes_policiais.csv` | 11. Operações policiais | `id_operacao`* (único por notícia), `nome_operacao`, `orgao`, `codigo_ibge`, `data_operacao`, `qtd_presos`, `qtd_mortos` |

**Pessoas.** `pessoa_chave` desambigua homônimos. Sem ela, o nome é usado
como chave. Uma mesma chave com nomes diferentes em qualquer arquivo é rejeitada.

**Facções e veículos** são criados a partir dos nomes citados. A carga lista
as facções novas: confira se não há grafias diferentes da mesma facção.

**Domínios** (papéis, tipos de relação, atividade, item) são tabelas `ref_*`.
Novos valores entram por migração, sem mudar a estrutura das tabelas.

## Conversão dos arquivos originais

O dataset de notícias original tem 78 campos numa única planilha. Converter
para este layout (um arquivo por eixo, uma linha por fato) depende do
dicionário dos arquivos originais (questão Q5 da spec) e é feito antes da carga.
