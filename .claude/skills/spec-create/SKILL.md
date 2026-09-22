---
name: spec-create
description: Cria uma nova spec em specs/ para uma funcionalidade do Mindy, a partir de uma ideia ou pedido do usuário. Use quando o usuário pedir para especificar, planejar ou escrever a spec de uma nova funcionalidade, endpoint ou mudança, antes de qualquer código ser escrito.
---

# spec-create

Cria uma nova spec em `specs/`, seguindo o fluxo spec-driven deste projeto
(ver [`specs/README.md`](../../../specs/README.md)). Esta skill **não
escreve código** — produz apenas o documento de spec.

## Quando usar

Sempre que o usuário pedir uma nova funcionalidade, endpoint, mudança de
comportamento ou integração, e ainda não existir uma spec `approved` ou
`in-progress` cobrindo o pedido em `specs/`.

## Passos

1. **Verifique specs existentes.** Se `specs/` tem mais de meia dúzia de
   specs, **delegue a varredura** ao agent `Explore` (somente leitura),
   pedindo: quais specs tocam o mesmo assunto, qual o `Status` de cada uma e
   se alguma já cobre o pedido. Traga de volta só o resumo — o conteúdo das
   specs não precisa entrar neste contexto. Com poucas specs, ou quando o
   usuário já indicou qual é a relacionada, leia direto aqui: abrir agent
   para isso custa mais do que resolve.
   Se o pedido é uma extensão de uma spec existente ainda `draft`/`approved`,
   prefira editá-la em vez de criar uma nova.

2. **Leia o contexto do projeto — por seção, não por documento.** Carregue
   apenas o trecho que o pedido exige; documento inteiro é exceção e precisa
   de motivo. Mapa de onde procurar:

   | Assunto do pedido | Onde ler |
   |---|---|
   | Contrato de endpoint, payload, status HTTP | `docs/ESPECIFICACAO-API.md` §2 (endpoints), §4 (modelos) |
   | Regra de negócio do MVP | `docs/REQUISITOS-FUNCIONAIS-MVP.md`, o `RF-N` correspondente |
   | PII, LGPD, credenciais | `docs/SEGURANCA.md` §4 (dados), §5 (aplicação), §6 (credenciais) |
   | Camada, interface, adapter | `docs/ARQUITETURA-APLICACAO.md` §3 (regra de dependência), §4 (integrações) |
   | O que não é persistido | `docs/SCHEMA-BANCO-DE-DADOS.md` §4 |
   | Não sabe onde está | `docs/ARQUITETURA-MINDY.md` (índice) primeiro |

   A única leitura de documento inteiro aqui é o `ARQUITETURA-MINDY.md`, e o
   motivo é que ele **é** o índice: curto, e serve para descobrir em qual
   documento procurar, não para extrair conteúdo. Toda outra leitura completa
   precisa da mesma justificativa escrita ao lado.

   As decisões transversais (API síncrona com timeout < 60s, auth via API
   Gateway da Zoe, LGPD sobre dados de zupper) já estão em
   [`.claude/CLAUDE.md`](../../CLAUDE.md), que está carregado — não releia
   `docs/` para confirmá-las.

3. **Faça perguntas de esclarecimento.** Não invente requisitos. Se o pedido
   do usuário for ambíguo em pontos que mudam o design (ex.: quem pode
   chamar o endpoint, o que acontece em erro de upstream, limites de
   volume), pergunte antes de escrever a spec. Prefira poucas perguntas
   diretas a assumir silenciosamente.

4. **Escreva a spec.** Crie
   `specs/<tipo>/<id-task>/<pequena-descricao>/spec.md` a partir de
   [`specs/_TEMPLATE.md`](../../../specs/_TEMPLATE.md):
   - O caminho segue a convenção `<tipo>/<id-task>/<pequena-descricao>` de
     [`.claude/CLAUDE.md`](../../CLAUDE.md), seção "Processo" — mesma do
     branch de trabalho, com os mesmos tipos do Conventional Commits.
   - `<id-task>` é o identificador da task no board (ex.: `142`). Se o
     usuário não informar, **pergunte** — não invente um id.
   - Preencha o campo `Autor` automaticamente com a identidade configurada
     no Claude Code, sem perguntar ao usuário: rode `git config user.name`
     e `git config user.email` e preencha como `Nome <email>`. Se o Git
     local não tiver isso configurado, use o e-mail do usuário disponível
     no contexto da sessão. Só pergunte ao usuário se nenhuma dessas fontes
     tiver a informação.
   - Preencha `Data` com a data atual.
   - Preencha todas as seções do template. Requisitos funcionais devem ser
     testáveis (Given/When/Then), não vagos.
   - A seção "Critérios de aceite" deve ser uma lista objetiva e
     verificável — é o que o `spec-test-harness` vai validar depois.
   - Se a spec implica mudança de arquitetura já documentada em `docs/`,
     diga isso explicitamente na seção "Design técnico" e liste, no plano
     de tarefas, a atualização do documento correspondente.
   - Deixe `Status: draft`.

5. **Apresente a spec para revisão.** Não avance para `approved`
   automaticamente — resuma a spec para o usuário e pergunte se pode
   marcar como `approved` (ou ajuste conforme o feedback). Só mude o
   `Status` no arquivo depois de confirmação explícita.

## O que não fazer

- Não escreva código, testes ou Terraform nesta skill — isso é trabalho do
  `spec-develop`.
- Não marque a spec como `approved` sem confirmação do usuário.
- Não crie specs redundantes com o que já está em `docs/` sem valor
  incremental — specs descrevem *mudanças/funcionalidades*, não repetem a
  arquitetura já documentada.
