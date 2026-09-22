
## CONTEXTO
O objetivo geral da proposta deste projeto de Trabalho de Conclusão de Curso é desenhar e modelar um banco de dados relacional capaz de abrigar os datasets produzidos pelas pesquisas do INViPS.
O primeiro deles é um dataset relacionando dados de homicídios a dados de infraestrutura, orgnanizados em 4 eixos:
Transportes;
Telecomunicações;
Energia;
Projetos Financiados por Bancos Nacionais ou Regionais de Desenvolvimento.
O segundo contém dados de cerca de 45 mil notícias, de dezenas de veículos de imprensa, datando de 2015 a 2023, contendo 78 campos informacionais, preenchidos por LLM e avaliados por humanos, com precisão mínima de 90%, que podem ser sintetizados sob eixos informacionais da seguinte forma:
Identificadores básicos;
Pessoas envolvidas;
Homicídio;
Gestão e estrutura faccional;
Disputas territoriais;
Confrontos e alianças;
Lavagem de Dinheiro;
Atividades Econômicas Ilícitas;
Atuação Política;
Apreensões;
 Operações Policiais.
Tal banco de dados será idealizado de acordo com um conjunto de atributos: 1) interoperabilidade, 2) reprodutibilidade, 3) controle de qualidade, 4) transparência, 5) escalaridade e 6) sustentabilidade dos dados por elas legados, bem como de possíveis pesquisas futuras, viabilizando também novas metodologias de pesquisa, demandantes de um grau de estruturação e qualificação de datasets de que o INViPS ainda não tem sido capaz de aportar.
Definição dos requisitos funcionais
Definição de quais dados serão e de que tipo
Definição de quem terá acesso a quais segmentos informacionais
Definição das principais consultas esperadas
Definição de requisitos arquiteturais
Volume esperado de dados
Concorrência esperada
Latência mínima exigida
Políticas de backup e disponibilidade?
Definição da tecnologia adotada
Definição do tipo de hospedagem (Cloud, On-premise, Híbrido)
Definições de segurança
Definição de modelo de escalabilidade
Plano de Migração e Manutenção
Definição de estratégias de backup e recuperação de dados
Desenho do projeto conceitual e lógico
Descrição da estrutura dos dados
Desenvolvimento do Modelo Entidade-Relacionamento (MER)
Desenvolvimento do Dicionário de Dados
A tarefa de conceber e modelar um banco de dados relacional para resolver o problema organizacional que é o déficit de governança de dados do INViPS constitui uma pesquisa de natureza aplicada, orientada à produção de um artefato tecnológico, mais especificamente, ao desenho de um processo produtivo cuja implementação foge, por limitação temporal, do escopo deste trabalho em si. Para tanto, utilizarei as diretrizes da Design Science Research Methodology (DSRM), formulada por Hevner et al., (2004) e aprofundada procedimentalmente por Peffers et al., (2007). Estrututrarei este percurso metodológico em 3 etapas.
Etapa 1: Definição de requisitos funcionais
Nesta etapa, conduzi entrevistas semiestruturadas com a coordenação técnica e o núcleo gestor do INViPS, a fim de captar diferentes perfis de uso, demandas e restrições de acesso, bem como catalogarei os dois datasets já existentes para inferir tipos de dados, granularidade e relacionamentos latentes.
Etapa 2: Modelagem conceitual e lógica
Nesta etapa, construirei os modelos conceituais e lógicos do banco de dados em si, conforme proposição de Connolly & Begg (2015) e Elmasri e Navathe (2016). Para tanto, aplicarei diretamente o referencial teórico legado por Codd (1974) e  Fagin(1977), normalizando dependências multivaloradas processando-as reduzindo-as à Forma Normal 4, apresentada por Fagin (1977).
Etapa 3: Definição de requisitos arquiteturais e escolha tecnológica
Elaborarei nesta etapa, uma matriz de decisão ponderada comparando Sistemas de Gerenciamento de Bancos de Dados (SGBD) candidatos, tais quais PostgreSQL, MySQL e SQL Server, bem como modelos de hospedagem, como cloud, on-premise e híbrido, segundo os critérios levantados na Etapa 1, como volume esperado, concorrência, latência, custo, requisitos de segurança e considerações de proteção de dados sensíveis (adesão à Lei Geral de Proteção de Dados).
DEFINIÇÃO DOS REQUISITOS FUNCIONAIS
EXPECTATIVAS ORGANIZACIONAIS
As entrevistas breves com o núcleo gestor e a coordenação técnica do INViPS indicaram preocupações difusas quanto a segurança e confiabilidade, havendo pouca demanda quanto a desempenho, usabilidade, manutenibilidade e portabilidade, evidenciando um perfil institucional orientado à priorização de controle de acessos e segurança em torno da integridade e da disponibilidade dos dados.
Também ficou clara a expectativa de manutenção do perfil institucional de operação sobre volumes relativamente baixo de dados, mas de alta complexidade ao longo do tempo, indicando fulcralidade do processo de normalização dos dados. Espera-se que os dados sejam centralizados num profissional especializado que disponibilizará dados sob encomenda dos grupos de pesquisa, havendo baixa necessidade de aporte de facilitação e simplificação do uso, bem como pequena importância em torno da garantia de baixa latência em função da expectativa de usos lentos. Dada a natureza pública dos dados utilizados, não há demanda de tratamento e proteção de dados sensíveis.
Tabela 2. Intensidade de expectativa sobre atributos do banco de dados em função da
