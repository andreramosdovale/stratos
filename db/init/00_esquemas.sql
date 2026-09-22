-- Executado pelo Postgres uma única vez, na criação do banco
-- (docker-entrypoint-initdb.d, em ordem alfabética).

CREATE SCHEMA nucleo;
CREATE SCHEMA infraestrutura;
CREATE SCHEMA noticias;

COMMENT ON SCHEMA nucleo IS 'Entidades compartilhadas entre datasets: localidades, fontes, lotes de carga, pessoas, facções e domínios.';
COMMENT ON SCHEMA infraestrutura IS 'Dataset Homicídios × Infraestrutura (transportes, telecomunicações, energia, projetos financiados).';
COMMENT ON SCHEMA noticias IS 'Dataset de notícias (2015–2023) com os 11 eixos informacionais preenchidos por LLM e avaliados por humanos.';
