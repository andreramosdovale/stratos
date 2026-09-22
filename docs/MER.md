# Modelo Entidade-Relacionamento

Modelo lógico implementado em `db/migrations/`. Colunas completas em
[`DICIONARIO-DADOS.md`](DICIONARIO-DADOS.md). As tabelas de domínio
(`ref_*`), as colunas de proveniência e `criado_em`/`atualizado_em` foram
omitidas dos diagramas para facilitar a leitura.

## Núcleo e Homicídios × Infraestrutura

```mermaid
erDiagram
  UF ||--o{ MUNICIPIO : contem
  MUNICIPIO ||--o{ HOMICIDIO : registra
  MUNICIPIO ||--o{ MEDICAO_INDICADOR : mede
  INDICADOR ||--o{ MEDICAO_INDICADOR : "é medido em"
  BANCO_DESENVOLVIMENTO ||--o{ PROJETO_FINANCIADO : financia
  PROJETO_FINANCIADO ||--|{ PROJETO_MUNICIPIO : atende
  MUNICIPIO ||--o{ PROJETO_MUNICIPIO : "é atendido"
  FONTE_DADO ||--o{ HOMICIDIO : origina
  FONTE_DADO ||--o{ MEDICAO_INDICADOR : origina
  FONTE_DADO ||--o{ PROJETO_FINANCIADO : origina
  LOTE_CARGA ||--o{ HOMICIDIO : carrega
  LOTE_CARGA ||--o{ MEDICAO_INDICADOR : carrega
  LOTE_CARGA ||--o{ PROJETO_FINANCIADO : carrega

  UF {
    smallint id PK "código IBGE"
    char sigla UK
  }
  MUNICIPIO {
    bigint id PK
    int codigo_ibge UK
    text nome
    smallint uf_id FK
  }
  HOMICIDIO {
    bigint id PK
    bigint municipio_id FK
    smallint ano
    int quantidade
    bigint fonte_dado_id FK
  }
  INDICADOR {
    bigint id PK
    text codigo UK
    text eixo FK
    text unidade
  }
  MEDICAO_INDICADOR {
    bigint id PK
    bigint municipio_id FK
    smallint ano
    bigint indicador_id FK
    numeric valor
  }
  BANCO_DESENVOLVIMENTO {
    bigint id PK
    text sigla UK
    text abrangencia FK
  }
  PROJETO_FINANCIADO {
    bigint id PK
    text codigo_origem
    bigint banco_id FK
    text eixo FK
    numeric valor_contratado
  }
  PROJETO_MUNICIPIO {
    bigint projeto_id PK,FK
    bigint municipio_id PK,FK
  }
```

## Notícias

```mermaid
erDiagram
  VEICULO_IMPRENSA ||--o{ NOTICIA : publica
  NOTICIA ||--o{ NOTICIA_MUNICIPIO : "ocorre em"
  NOTICIA ||--o{ NOTICIA_PESSOA : cita
  PESSOA ||--o{ NOTICIA_PESSOA : "é citada"
  NOTICIA ||--o{ HOMICIDIO_NOTICIADO : relata
  NOTICIA ||--o{ ESTRUTURA_FACCIONAL : descreve
  FACCAO ||--o{ ESTRUTURA_FACCIONAL : possui
  PESSOA |o--o{ ESTRUTURA_FACCIONAL : ocupa
  NOTICIA ||--o{ DISPUTA_TERRITORIAL : relata
  DISPUTA_TERRITORIAL ||--o{ DISPUTA_FACCAO : envolve
  FACCAO ||--o{ DISPUTA_FACCAO : disputa
  NOTICIA ||--o{ RELACAO_FACCIONAL : relata
  FACCAO ||--o{ RELACAO_FACCIONAL : "lado A / lado B"
  NOTICIA ||--o{ LAVAGEM_DINHEIRO : relata
  NOTICIA ||--o{ ATIVIDADE_ILICITA : relata
  NOTICIA ||--o{ ATUACAO_POLITICA : relata
  NOTICIA ||--o{ OPERACAO_POLICIAL : relata
  OPERACAO_POLICIAL |o--o{ APREENSAO : resulta
  NOTICIA ||--o{ APREENSAO : relata

  NOTICIA {
    bigint id PK
    text codigo_origem UK
    text url UK
    date data_publicacao
    bigint veiculo_id FK
  }
  NOTICIA_PESSOA {
    bigint noticia_id PK,FK
    bigint pessoa_id PK,FK
    text papel PK,FK
  }
  PESSOA {
    bigint id PK
    text chave_origem UK
    text nome
  }
  FACCAO {
    bigint id PK
    text nome UK
  }
  DISPUTA_TERRITORIAL {
    bigint id PK
    bigint noticia_id FK
    text territorio
  }
  RELACAO_FACCIONAL {
    bigint id PK
    bigint faccao_a_id FK
    bigint faccao_b_id FK
    text tipo FK
  }
  OPERACAO_POLICIAL {
    bigint id PK
    bigint noticia_id FK
    text codigo_origem
  }
  APREENSAO {
    bigint id PK
    bigint operacao_id FK
    text item FK
    numeric quantidade
  }
```

As tabelas de eixo de notícias também podem referenciar `MUNICIPIO`,
`FACCAO` e `PESSOA` (FK opcional). Esses vínculos ficaram fora do diagrama
para não poluí-lo.

## Decisões de normalização (até a 4FN)

| Situação | Decisão |
|---|---|
| Uma notícia cita **várias pessoas**, **vários municípios** e **vários fatos** de cada eixo, e esses fatos são independentes entre si. | Cada fato multivalorado tem sua própria tabela ligada a `noticia`. Colocar pessoas × facções × apreensões numa tabela só criaria dependências multivaloradas não triviais (violação da 4FN). |
| Uma disputa territorial envolve **várias facções**. | `disputa_faccao` associativa. |
| Um projeto atende **vários municípios**. | `projeto_municipio` associativa. |
| Indicadores de infraestrutura variam por eixo e ainda não são conhecidos um a um. | Catálogo `indicador` + `medicao_indicador` (município × ano × indicador). Evita uma coluna por indicador e mantém a chave `(municipio, ano, indicador, fonte)` como única determinante. |
| Nomes de facção, veículo e pessoa se repetem entre notícias. | Entidades em `nucleo` referenciadas por FK (sem redundância, sem anomalia de atualização). |
| Domínios fechados (papel, tipo de relação, item...). | Tabelas `ref_*` com FK, em vez de `enum` ou texto livre. |
| Proveniência (origem, validação, lote) é atributo **de cada fato** extraído. | As colunas ficam em cada tabela de eixo. Elas dependem da chave do fato, não da notícia. |
| `uf_id` de município é derivável do código IBGE. | Mantido por legibilidade, com `CHECK (codigo_ibge / 100000 = uf_id)` para impedir inconsistência. |
