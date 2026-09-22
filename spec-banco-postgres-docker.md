# Spec: Banco de dados relacional PostgreSQL em Docker para os datasets do INViPS

| Campo | Valor |
|---|---|
| Status | done |
| Autor | André Ramos do Vale <andre_ramosdovale@outlook.com> |
| Data | 2026-09-22 |
| Tipo | feat |
| Contexto | `file.md`, `img.png` (Tabela 2 — intensidade de demanda por atributo) |

---

## 1. Contexto

O INViPS tem um déficit de governança de dados: os datasets produzidos pelas
pesquisas não estão num repositório estruturado, normalizado e com controle de
acesso. Este TCC (DSRM, Hevner et al. 2004; Peffers et al. 2007) desenha um
banco relacional para abrigar, de início, dois datasets:

1. **Homicídios × Infraestrutura**: dados de homicídios cruzados com quatro
   eixos de infraestrutura: Transportes, Telecomunicações, Energia e Projetos
   Financiados por Bancos Nacionais ou Regionais de Desenvolvimento.
2. **Notícias**: cerca de 45 mil notícias de dezenas de veículos, de 2015 a 2023,
   com 78 campos preenchidos por LLM e avaliados por humanos (precisão mínima
   de 90%), agrupados em 11 eixos: Identificadores básicos; Pessoas
   envolvidas; Homicídio; Gestão e estrutura faccional; Disputas territoriais;
   Confrontos e alianças; Lavagem de dinheiro; Atividades econômicas ilícitas;
   Atuação política; Apreensões; Operações policiais.

O banco precisa atender aos atributos de **interoperabilidade,
reprodutibilidade, controle de qualidade, transparência, escalabilidade e
sustentabilidade** dos dados.

### 1.1 Expectativas organizacionais (entrevistas, Etapa 1)

| Atributo | Intensidade de demanda | Consequência para o design |
|---|---|---|
| Desempenho | Baixa | Sem tuning agressivo, réplicas ou cache. Índices só onde as consultas principais pedirem. |
| Usabilidade | Baixa | Sem interface gráfica para o usuário final. O acesso é mediado por um profissional especializado (curador). |
| Manutenibilidade | Baixa | Stack mínima: um contêiner PostgreSQL e scripts versionados. |
| Portabilidade | Baixa | Docker é usado por reprodutibilidade, não por exigência de portabilidade. |
| **Segurança** | **Alta** | Papéis com menor privilégio, autenticação forte, porta não exposta publicamente, segredos fora do repositório. |
| Armazenamento | Baixa | Volume baixo (dezenas de milhares de linhas por dataset): um único nó basta. |
| Latência | Baixa | Uso lento e sob encomenda, então não há meta de tempo de resposta. As consultas de referência só precisam terminar. |
| **Integridade** | **Alta** | Normalização até a 4FN, constraints declarativas (PK/FK/CHECK/UNIQUE), checksums de página, trilha de auditoria. |
| Proteção de dados sensíveis | Baixa | Os dados são públicos, então não há exigência de anonimização/pseudonimização. O controle de acesso continua por segurança e integridade. |

Perfil de uso: **volume baixo, alta complexidade relacional, poucos usuários,
consultas lentas e sob encomenda**, com dados centralizados num curador que os
entrega aos grupos de pesquisa.

## 2. Objetivo

Entregar um ambiente PostgreSQL **reprodutível**, provisionado via Docker
Compose, com:

- o esquema lógico dos dois datasets normalizado até a 4FN;
- papéis de acesso segmentados (administrador, curador, leitor);
- migrações versionadas, capazes de reconstruir o banco do zero;
- rotina de backup e restauração testada;
- metadados de qualidade e proveniência para os campos preenchidos por LLM.

## 3. Escopo

### Dentro do escopo
- `docker-compose.yml` com o serviço PostgreSQL e o serviço de migração.
- Esquemas, tabelas, constraints, índices e comentários (`COMMENT ON`) que
  servem de dicionário de dados consultável no próprio banco.
- Papéis e privilégios.
- Trilha de auditoria de escrita.
- Scripts de backup lógico e de restauração.
- Carga inicial (ETL simples) dos dois datasets a partir dos arquivos de
  origem, via área de *staging*.
- Documentação: MER, dicionário de dados e runbook de operação.

### Fora do escopo
- Implantação em produção (cloud/on-premise/híbrido): a decisão de hospedagem
  sai da matriz de decisão da Etapa 3. Esta spec entrega um artefato que roda
  igual em qualquer um desses cenários.
- Alta disponibilidade (replicação, failover).
- Interface web, API ou dashboards para o usuário final.
- Anonimização de dados, já que os dados são públicos.
- Reprocessamento por LLM dos campos das notícias.

## 4. Requisitos funcionais

### RF-1: Subida reprodutível do ambiente
- **Given** uma máquina com Docker e Docker Compose, e um `.env` criado a partir
  de `.env.example`
- **When** o operador executa `docker compose up -d`
- **Then** o contêiner `db` fica `healthy` (healthcheck `pg_isready`) em até 60 s,
  **and** o serviço `migrate` aplica todas as migrações pendentes e termina com
  código 0.

### RF-2: Reconstrução do zero
- **Given** o volume de dados removido (`docker compose down -v`)
- **When** o ambiente sobe de novo
- **Then** o esquema resultante é idêntico ao anterior, comparando
  `pg_dump --schema-only` antes e depois.

### RF-3: Esquema do dataset Homicídios × Infraestrutura
- **Given** o banco migrado
- **When** o curador consulta o esquema `infraestrutura`
- **Then** existem entidades para homicídio por município e ano, para um
  catálogo de indicadores classificado pelos 4 eixos (transportes,
  telecomunicações, energia, projetos financiados) com as medições por
  município e ano, e para projetos financiados ligados a um banco de
  desenvolvimento e aos municípios atendidos. Todas têm FK para a localidade
  comum (`nucleo.municipio`).

### RF-4: Esquema do dataset de Notícias
- **Given** o banco migrado
- **When** o curador consulta o esquema `noticias`
- **Then** cada um dos 11 eixos informacionais está representado por uma ou
  mais tabelas ligadas a `noticias.noticia`, **and** os atributos
  multivalorados (várias pessoas, facções, apreensões… por notícia) estão em
  tabelas associativas próprias, sem listas em colunas de texto (1FN) e sem
  combinar fatos independentes na mesma tabela (4FN).

### RF-5: Proveniência e qualidade dos campos preenchidos por LLM
- **Given** um campo informacional de notícia preenchido por LLM
- **When** ele é gravado
- **Then** o registro guarda `origem` (`llm` | `humano`), `modelo_llm`
  (quando houver), `validado_por_humano` (boolean), `validado_em` e
  `lote_carga_id`, **and** é possível listar a proporção de campos validados
  por eixo com uma consulta.

### RF-6: Controle de acesso por papel
- **Given** os papéis `invips_admin`, `invips_curador` e `invips_leitor`
- **When** um usuário com `invips_leitor` tenta `INSERT`, `UPDATE`, `DELETE`
  ou DDL em qualquer esquema de dados
- **Then** a operação falha com `permission denied`,
  **and** `SELECT` nos esquemas `nucleo`, `infraestrutura` e `noticias` funciona.
- **Given** `invips_curador`
- **When** tenta DDL (`CREATE`/`ALTER`/`DROP`)
- **Then** falha. DML nos esquemas de dados funciona.

### RF-7: Auditoria de escrita
- **Given** qualquer `INSERT`, `UPDATE` ou `DELETE` nas tabelas dos esquemas de dados
- **When** a transação é confirmada
- **Then** uma linha é gravada em `auditoria.log_alteracao` com tabela,
  operação, chave primária, valores antigos/novos (`jsonb`), usuário
  (`session_user`) e timestamp,
  **and** nenhum papel além de `invips_admin` pode alterar ou apagar linhas de
  `auditoria.log_alteracao`.

### RF-8: Carga inicial separada, via staging
- **Given** os CSVs de um conjunto de carga (`nucleo`, `infraestrutura` ou
  `noticias`) no layout canônico de `db/carga-inicial/README.md`
- **When** o curador executa `docker compose --profile carga run --rm carga <conjunto>`
- **Then** os dados entram primeiro em `staging` (tipos `text`), são validados
  e transformados para os esquemas finais numa única transação,
  **and** se qualquer validação ou constraint falhar, nada é gravado nos
  esquemas finais e o script lista as linhas rejeitadas (arquivo, linha,
  motivo).
- **Given** um conjunto já carregado
- **When** a carga inicial dele é executada de novo
- **Then** ela é recusada sem alterar nada.
- Os scripts de carga inicial ficam **separados** das migrações de esquema
  (ver §6.8): as migrações nunca carregam dados de pesquisa, e `docker compose up`
  nunca dispara uma carga.

### RF-9: Backup
- **Given** o ambiente rodando
- **When** o operador executa `scripts/backup.sh` (ou a rotina agendada dispara)
- **Then** é gerado um arquivo `pg_dump -Fc` com data no nome em `./backups/`,
  com checksum SHA-256 ao lado, **and** arquivos com mais de N dias
  (configurável, padrão 30) são removidos.

### RF-10: Restauração
- **Given** um arquivo de backup válido
- **When** o operador executa `scripts/restore.sh <arquivo>` num banco vazio
- **Then** o banco restaurado tem a mesma contagem de linhas por tabela que a
  origem, e o script termina com código 0.

### RF-11: Dicionário de dados consultável
- **Given** o banco migrado
- **When** qualquer papel consulta `nucleo.v_dicionario_dados`
- **Then** toda tabela e coluna dos esquemas de dados aparece com descrição
  não vazia (vinda de `COMMENT ON`), tipo e nulabilidade.

### RF-12: Consultas principais
- **Given** os dois datasets carregados
- **When** o curador executa as consultas de referência em `db/queries/`
- **Then** cada uma retorna sem erro. Consultas mínimas:
  - homicídios por município e ano × presença de cada eixo de infraestrutura;
  - notícias por facção e período, com disputas territoriais e confrontos/alianças;
  - apreensões e operações policiais por município e ano;
  - cruzamento notícia ↔ município ↔ indicadores de infraestrutura.

> A lista final de consultas depende das entrevistas (ver Q3 em §9).

## 5. Requisitos não funcionais

| ID | Requisito | Verificação |
|---|---|---|
| RNF-1 | Autenticação `scram-sha-256` para todas as conexões; `trust` proibido. | Inspeção de `pg_hba.conf` e de `SHOW password_encryption`. |
| RNF-2 | Porta 5432 publicada apenas em `127.0.0.1` por padrão. | `docker compose config` / `docker port`. |
| RNF-3 | Nenhum segredo versionado; senhas via `.env` (ignorado no git) ou Docker secrets. | `.gitignore` contém `.env`; só `.env.example` é versionado, sem valores reais. |
| RNF-4 | Nenhum papel de aplicação ou usuário é `SUPERUSER`. | `SELECT rolname FROM pg_roles WHERE rolsuper` retorna só `postgres`. |
| RNF-5 | Data checksums habilitados no cluster. | `SHOW data_checksums` = `on`. |
| RNF-6 | Imagem com versão fixa (major e minor), sem `latest`. | Inspeção do `docker-compose.yml`. |
| RNF-7 | Encoding UTF-8 e collation `pt_BR` (ou ICU `und-x-icu`) para ordenação correta de nomes em português. | `SHOW server_encoding`; `\l`. |
| RNF-8 | `timestamptz` para todos os instantes, com fuso `America/Sao_Paulo` na sessão. | Revisão das migrações. |
| RNF-9 | RPO ≤ 24 h (backup diário); RTO ≤ 1 h para o volume esperado. | Teste de restauração (RF-10) cronometrado. |

## 6. Design técnico

### 6.1 Tecnologia

- **SGBD:** PostgreSQL 18 (imagem oficial `postgres:18.x`). A escolha é
  confirmada pela matriz de decisão da Etapa 3. Por ora os critérios que pesam
  são segurança/integridade altas, licença livre, suporte maduro a
  constraints, `jsonb`, RLS e extensões (ex.: PostGIS, se Q4 exigir).
- **Orquestração:** Docker Compose, com um único nó.
- **Migrações:** Flyway (imagem `flyway/flyway`), com arquivos
  `V<n>__<descricao>.sql` versionados. O Flyway garante a ordem e registra um
  checksum por migração, o que atende à reprodutibilidade.

> Nota (PostgreSQL 18): a imagem oficial passou a usar
> `PGDATA=/var/lib/postgresql/18/docker`, e o volume deve ser montado em
> `/var/lib/postgresql`, não mais em `/var/lib/postgresql/data`. O PG 18
> também habilita data checksums por padrão no `initdb`.

### 6.2 Estrutura de arquivos

```
.
├── docker-compose.yml
├── .env.example
├── db/
│   ├── init/                 # executado só na 1ª subida (docker-entrypoint-initdb.d)
│   │   └── 00_roles.sql      # cria papéis e o banco; revoga PUBLIC
│   ├── migrations/           # Flyway: só DDL, papéis e dados de referência
│   ├── carga-inicial/        # separado das migrações (RF-8, §6.8)
│   │   ├── executar.sh       # ponto de entrada do serviço `carga`
│   │   ├── comum/            # funções de validação
│   │   ├── nucleo/           # municípios
│   │   ├── infraestrutura/   # homicídios, indicadores, projetos
│   │   ├── noticias/         # notícias e os 11 eixos
│   │   └── exemplo/          # CSVs fictícios para testar o pipeline
│   ├── queries/              # consultas de referência (RF-12)
│   └── config/
│       └── pg_hba.conf
├── dados/                    # CSVs reais de origem (ignorado no git)
├── scripts/
│   ├── backup.sh
│   ├── restore.sh
│   ├── criar-pesquisador.sh
│   ├── gerar-dicionario.sh   # docs/DICIONARIO-DADOS.md a partir do banco
│   └── verificar.sh          # roteiro automatizado dos critérios de aceite
├── backups/                  # ignorado no git
└── docs/
    ├── MER.md                # diagrama entidade-relacionamento
    ├── DICIONARIO-DADOS.md   # gerado a partir de v_dicionario_dados
    └── RUNBOOK.md
```

### 6.3 Docker Compose

Três serviços:
- `db`: `postgres:18.x` com versão fixa, porta só em `127.0.0.1`,
  `pg_hba.conf` próprio, healthcheck `pg_isready`, volume em `/var/lib/postgresql`.
- `migrate`: Flyway, roda como `invips_admin` a cada `up` e termina.
- `carga`: psql, roda como `invips_curador`, fica no profile `carga` e **só
  roda quando chamado explicitamente**.

Senhas vêm do `.env` (fora do git). O `.env.example` traz só nomes de variáveis.

### 6.4 Organização lógica (esquemas)

| Esquema | Conteúdo |
|---|---|
| `nucleo` | Entidades compartilhadas: `uf`, `municipio` (código IBGE como chave natural única), `veiculo_imprensa`, `fonte_dado`, `lote_carga`, `faccao`, `pessoa`. Views do dicionário de dados. |
| `infraestrutura` | `homicidio` (município × ano × fonte), `indicador` (catálogo classificado por `eixo`: transportes, telecomunicações, energia, projetos financiados), `medicao_indicador` (município × ano × indicador), `banco_desenvolvimento`, `projeto_financiado` e `projeto_municipio` (associativa). O catálogo de indicadores permite novos indicadores sem DDL, já que as colunas de cada eixo ainda não são conhecidas (Q5). |
| `noticias` | `noticia` (identificadores básicos, veículo, data, URL), `noticia_municipio` e as tabelas de cada eixo: `noticia_pessoa` (papel da pessoa na notícia), `homicidio_noticiado`, `estrutura_faccional`, `disputa_territorial` + `disputa_faccao`, `relacao_faccional` (confronto/aliança, com `tipo`), `lavagem_dinheiro`, `atividade_ilicita`, `atuacao_politica`, `apreensao` (item, quantidade, unidade), `operacao_policial`. Cada tabela de eixo tem `noticia_id` FK e as colunas de proveniência do RF-5. |
| `auditoria` | `log_alteracao` e a função de trigger genérica. |
| `staging` | Tabelas espelho dos CSVs de origem, só com `text`, recriadas a cada carga inicial. |

O MER definitivo e as dependências multivaloradas que justificam cada
decomposição na 4FN são entregáveis da Etapa 2 (`docs/MER.md`). A tabela acima
é o ponto de partida.

Convenções:
- PK surrogate `bigint GENERATED ALWAYS AS IDENTITY`, mais `UNIQUE` na chave
  natural quando houver (ex.: código IBGE, URL da notícia).
- Domínios fechados (tipo de relação faccional, tipo de apreensão, origem
  `llm`/`humano`) como tabelas de referência com FK, não `enum`, para permitir
  evolução sem DDL.
- `CHECK` para faixas válidas (ano entre 2015 e 2023 nas notícias,
  quantidades ≥ 0, etc.).
- Colunas `criado_em`/`atualizado_em timestamptz NOT NULL DEFAULT now()`.

### 6.5 Papéis e privilégios

| Papel | LOGIN | Privilégios |
|---|---|---|
| `postgres` | sim (só local, bootstrap) | superuser; senha em secret; não é usado no dia a dia. |
| `invips_admin` | sim | dono dos esquemas; DDL; executa migrações. |
| `invips_curador` | sim | `SELECT/INSERT/UPDATE/DELETE` em `nucleo`, `infraestrutura`, `noticias`, `staging`; `SELECT` em `auditoria`. |
| `invips_leitor` | não (grupo) | `SELECT` em `nucleo`, `infraestrutura`, `noticias`. Usuários nominais de pesquisadores herdam este papel. |
| `invips_backup` | sim | `pg_read_all_data`, usado só pelo `backup.sh`. |

- `REVOKE ALL ON SCHEMA public FROM PUBLIC` e `REVOKE CREATE` global.
- `ALTER DEFAULT PRIVILEGES` para que tabelas novas herdem as permissões.
- Segmentação por dataset (ex.: um grupo que só vê `infraestrutura`) é feita
  com papéis de leitura por esquema, caso Q2 confirme essa necessidade.

### 6.6 Backup e recuperação

- Backup lógico diário: `pg_dump -Fc` executado via `docker compose exec`,
  agendado pelo cron/Agendador de Tarefas do host.
- Retenção de 30 dias local. Recomenda-se uma cópia fora do host, cujo
  destino depende da decisão de hospedagem.
- Teste de restauração obrigatório a cada mudança de major do PostgreSQL e,
  pelo menos, mensalmente (registrado no `RUNBOOK.md`).
- WAL archiving/PITR fica fora do escopo: com volume baixo e escrita
  esporádica (cargas em lote), RPO de 24 h é suficiente. Revisar se as cargas
  ficarem contínuas.

### 6.7 Manutenção e evolução

- Toda mudança de esquema entra como nova migração Flyway. Migrações já
  aplicadas nunca são editadas.
- Novos datasets entram como novo esquema, reaproveitando `nucleo`
  (escalabilidade/sustentabilidade).
- Upgrade de major: `pg_dump` → sobe a nova imagem com volume novo →
  `pg_restore` → valida contagens (mesmo procedimento do RF-10).

### 6.8 Carga inicial (separada das migrações)

- As migrações (`db/migrations/`) contêm só estrutura: esquemas, tabelas,
  constraints, papéis, auditoria, comentários e dados de referência
  (UFs, domínios fechados). Nenhum dado de pesquisa.
- A carga inicial fica em `db/carga-inicial/`, um diretório por conjunto
  (`nucleo`, `infraestrutura`, `noticias`), cada um com
  `01_staging.sql` (cria as tabelas `staging` e faz `\copy` dos CSVs),
  `02_validacao.sql` (acumula rejeições e aborta se houver alguma) e
  `03_transformacao.sql` (insere nos esquemas finais).
- Ordem obrigatória: `nucleo` → `infraestrutura` → `noticias`. O conjunto
  `todos` executa na ordem.
- Cada execução roda em `psql --single-transaction -v ON_ERROR_STOP=1` e
  registra um `nucleo.lote_carga` com o SHA-256 de cada arquivo.
- Layout canônico dos CSVs (UTF-8, cabeçalho, separador `,`, listas com `|`)
  documentado em `db/carga-inicial/README.md`. Converter os arquivos originais
  para esse layout depende de Q5.

## 7. Critérios de aceite

> Verificados em 2026-09-22 com os CSVs fictícios de `db/carga-inicial/exemplo/`: `scripts/verificar.sh` (automáticos) e o roteiro manual de `docs/RUNBOOK.md` (reconstrução do zero, carga rejeitada, backup/restauração).

- [x] `docker compose up -d` numa máquina limpa deixa `db` `healthy` e `migrate` termina com código 0.
- [x] `docker compose down -v && docker compose up -d` produz `pg_dump --schema-only` idêntico ao anterior.
- [x] `SHOW data_checksums` retorna `on`; `SHOW password_encryption` retorna `scram-sha-256`.
- [x] `pg_hba.conf` não contém `trust`.
- [x] A porta 5432 está publicada só em `127.0.0.1`.
- [x] Nenhum arquivo versionado contém senha; `.env`, `secrets/` e `backups/` estão no `.gitignore`.
- [x] Só `postgres` tem `rolsuper = true`.
- [x] Com `invips_leitor`: `SELECT` funciona e `INSERT`/`UPDATE`/`DELETE`/`CREATE` falham com `permission denied`.
- [x] Com `invips_curador`: DML funciona e DDL falha.
- [x] Um `UPDATE` feito pelo curador gera uma linha em `auditoria.log_alteracao` com valores antigos e novos; o curador não consegue apagá-la.
- [x] Os 4 eixos de infraestrutura e os 11 eixos de notícias estão representados no esquema, com FKs válidas.
- [x] Nenhuma coluna guarda listas delimitadas; cada atributo multivalorado tem tabela própria (revisão contra o MER).
- [x] Todo campo de notícia preenchido por LLM tem `origem`, `validado_por_humano` e `lote_carga_id`.
- [x] Uma carga com uma linha inválida é rejeitada por inteiro e o script relata a linha e o motivo.
- [x] Nenhum arquivo em `db/migrations/` insere dados de pesquisa; `docker compose up` não executa carga.
- [x] Repetir a carga inicial de um conjunto já carregado é recusado sem alterações.
- [x] Os dados carregados batem em contagem de registros com os CSVs de origem (verificado com os CSVs de exemplo; com os reais, ~45 mil notícias).
- [x] `nucleo.v_dicionario_dados` não tem descrição vazia para nenhuma tabela ou coluna dos esquemas de dados.
- [x] Todas as consultas em `db/queries/` executam sem erro.
- [x] `backup.sh` gera `.dump` + `.sha256`; `restore.sh` num banco vazio reproduz as contagens por tabela em menos de 1 h.

## 8. Plano de tarefas

1. Estrutura do repositório, `.gitignore`, `.env.example`, `secrets/` (placeholder).
2. `docker-compose.yml` com `db` (imagem fixada, healthcheck, volume, `pg_hba.conf`).
3. `db/init/00_roles.sql`: papéis, revogações e default privileges.
4. Migração `V1__nucleo.sql`: UF, município, fontes, lotes, pessoa, facção e tabelas de referência.
5. Migração `V2__infraestrutura.sql`.
6. Migração `V3__noticias.sql`, uma seção por eixo.
7. Migração `V4__auditoria.sql`: tabela, função e triggers.
8. Migração `V5__dicionario.sql`: `COMMENT ON` e `v_dicionario_dados`.
9. Serviço `migrate` (Flyway) no Compose.
10. Carga inicial separada em `db/carga-inicial/` (nucleo, infraestrutura, noticias), com serviço `carga` no profile `carga` e CSVs de exemplo.
11. `db/queries/` com as consultas de referência.
12. `scripts/backup.sh` e `scripts/restore.sh`, com agendamento documentado.
13. `docs/MER.md`, `docs/DICIONARIO-DADOS.md` e `docs/RUNBOOK.md`.
14. Roteiro de verificação dos critérios de aceite (§7).

## 9. Questões em aberto

- ~~Q1: Latência~~: **resolvida**. A demanda é Baixa (erro na Tabela 2).
- **Q2: Segmentação de acesso por dataset/eixo.** Algum grupo de pesquisa deve
  ver só parte dos dados (ex.: só infraestrutura, ou notícias sem o eixo
  "Pessoas envolvidas")? Se sim, entram papéis por esquema ou RLS.
- **Q3: Consultas principais.** A lista do RF-12 é inferida dos eixos e
  precisa ser validada com a coordenação técnica.
- **Q4: Granularidade geográfica.** Os dados de infraestrutura são por
  município ou têm coordenadas/geometrias? Se tiverem geometrias, entra
  PostGIS (`postgis/postgis:18-*`).
- **Q5: Formato e dicionário dos arquivos de origem** (CSV, XLSX, os 78 campos
  das notícias) para desenhar o `staging` e o ETL.
- **Q6: Pessoas nomeadas nas notícias.** Mesmo com os dados sendo públicos,
  guardar nomes de pessoas envolvidas em crimes num banco estruturado é
  tratamento de dado pessoal pela LGPD (art. 7º, §§3º-4º; art. 11 se houver
  dado sensível). Vale confirmar a base legal (pesquisa, art. 7º IV) e
  reavaliar a classificação "Baixa" de proteção de dados sensíveis.
- **Q7: Hospedagem.** Fica para a matriz da Etapa 3. A spec não depende dela,
  mas o destino do backup off-site depende.
