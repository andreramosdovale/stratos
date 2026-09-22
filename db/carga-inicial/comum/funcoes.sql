-- Funções de apoio da carga inicial. Vivem em pg_temp: somem ao fim da sessão
-- e não deixam rastro no esquema.

CREATE TEMP TABLE rejeicao (
  arquivo text   NOT NULL,
  linha   bigint,
  motivo  text   NOT NULL
);

-- Recria staging.<nome> com uma coluna text por campo do CSV, mais o número
-- da linha (a linha 1 do arquivo é o cabeçalho).
CREATE FUNCTION pg_temp.criar_staging(nome text, colunas text[]) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE format('DROP TABLE IF EXISTS staging.%I', nome);
  EXECUTE format(
    'CREATE TABLE staging.%I (linha bigint GENERATED ALWAYS AS IDENTITY (START 2), %s)',
    nome,
    (SELECT string_agg(format('%I text', c), ', ') FROM unnest(colunas) AS c));
END $$;

-- Remove espaços nas pontas e troca texto vazio por NULL em todas as colunas.
CREATE FUNCTION pg_temp.limpar(nome text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  sets text;
BEGIN
  SELECT string_agg(format('%1$I = NULLIF(btrim(%1$I), %2$L)', column_name, ''), ', ')
    INTO sets
  FROM information_schema.columns
  WHERE table_schema = 'staging' AND table_name = nome AND column_name <> 'linha';
  EXECUTE format('UPDATE staging.%I SET %s', nome, sets);
END $$;

-- Registra como rejeitada toda linha de staging.<nome> que satisfaz a condição.
CREATE FUNCTION pg_temp.checar(nome text, condicao text, motivo text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE format(
    'INSERT INTO pg_temp.rejeicao SELECT %L, linha, %s FROM staging.%I WHERE %s',
    nome || '.csv', motivo, nome, condicao);
END $$;

CREATE FUNCTION pg_temp.checar_obrigatorio(nome text, VARIADIC colunas text[]) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  c text;
BEGIN
  FOREACH c IN ARRAY colunas LOOP
    PERFORM pg_temp.checar(nome, format('%I IS NULL', c), format('%L', c || ' é obrigatório'));
  END LOOP;
END $$;

CREATE FUNCTION pg_temp.checar_tipo(nome text, coluna text, tipo text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_temp.checar(nome,
    format('%1$I IS NOT NULL AND NOT pg_input_is_valid(%1$I, %2$L)', coluna, tipo),
    format('%L || %I', coluna || ' não é ' || tipo || ' válido: ', coluna));
END $$;

-- Valor numérico (quando válido) não pode ficar abaixo do mínimo.
CREATE FUNCTION pg_temp.checar_minimo(nome text, coluna text, tipo text, minimo numeric) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_temp.checar(nome,
    format('CASE WHEN pg_input_is_valid(%1$I, %2$L) THEN %1$I::numeric < %3$s ELSE false END',
           coluna, tipo, minimo),
    format('%L || %I', coluna || ' menor que ' || minimo || ': ', coluna));
END $$;

-- A coluna (quando preenchida) precisa existir no conjunto devolvido por ref_sql.
CREATE FUNCTION pg_temp.checar_ref(nome text, coluna text, ref_sql text, descricao text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_temp.checar(nome,
    format('%1$I IS NOT NULL AND %1$I NOT IN (%2$s)', coluna, ref_sql),
    format('%L || %I', coluna || ' não encontrado em ' || descricao || ': ', coluna));
END $$;

-- Cada item de uma lista separada por '|' precisa existir em ref_sql.
CREATE FUNCTION pg_temp.checar_ref_lista(nome text, coluna text, ref_sql text, descricao text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_temp.checar(nome,
    format('EXISTS (SELECT 1 FROM unnest(string_to_array(%1$I, %3$L)) AS i
                    WHERE btrim(i) NOT IN (%2$s))', coluna, ref_sql, '|'),
    format('%L || %I', coluna || ' tem item não encontrado em ' || descricao || ': ', coluna));
END $$;

CREATE FUNCTION pg_temp.checar_unico(nome text, expressao text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_temp.checar(nome,
    format('(%1$s) IN (SELECT %1$s FROM staging.%2$I GROUP BY %1$s HAVING count(*) > 1)',
           expressao, nome),
    format('%L', 'duplicado: ' || expressao));
END $$;

-- Colunas de proveniência dos eixos de notícias (RF-5).
CREATE FUNCTION pg_temp.checar_proveniencia(nome text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_temp.checar_obrigatorio(nome, 'origem');
  PERFORM pg_temp.checar_ref(nome, 'origem',
    'SELECT codigo FROM nucleo.ref_origem_preenchimento', 'ref_origem_preenchimento');
  PERFORM pg_temp.checar_tipo(nome, 'validado_por_humano', 'boolean');
  PERFORM pg_temp.checar_tipo(nome, 'validado_em', 'timestamptz');
  PERFORM pg_temp.checar(nome, 'origem = ''humano'' AND modelo_llm IS NOT NULL',
    '''modelo_llm só pode ser preenchido quando origem = llm''');
  PERFORM pg_temp.checar(nome,
    'CASE WHEN pg_input_is_valid(coalesce(validado_por_humano, ''false''), ''boolean'')
          THEN coalesce(validado_por_humano, ''false'')::boolean <> (validado_em IS NOT NULL)
          ELSE false END',
    '''validado_em deve ser preenchido se e só se validado_por_humano = true''');
END $$;

-- Aborta a transação (e portanto a carga inteira) se houver rejeições.
CREATE FUNCTION pg_temp.abortar_se_rejeitado() RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  n bigint;
BEGIN
  SELECT count(*) INTO n FROM pg_temp.rejeicao;
  IF n > 0 THEN
    RAISE EXCEPTION 'carga abortada: % linha(s) rejeitada(s); nada foi gravado', n;
  END IF;
END $$;

-- Carga inicial acontece uma vez por conjunto.
CREATE FUNCTION pg_temp.exigir_primeira_carga(conjunto text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM nucleo.lote_carga l WHERE l.conjunto = exigir_primeira_carga.conjunto) THEN
    RAISE EXCEPTION 'a carga inicial de "%" já foi executada; nada foi alterado', conjunto;
  END IF;
END $$;

CREATE FUNCTION pg_temp.exigir_carregado(conjunto text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM nucleo.lote_carga l WHERE l.conjunto = exigir_carregado.conjunto) THEN
    RAISE EXCEPTION 'carregue o conjunto "%" antes deste', conjunto;
  END IF;
END $$;

-- Ao fim da carga, apaga as tabelas de staging: os dados já estão nos
-- esquemas finais e a área volta a ficar vazia.
CREATE FUNCTION pg_temp.esvaziar_staging() RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  t text;
BEGIN
  FOR t IN SELECT tablename FROM pg_tables WHERE schemaname = 'staging' LOOP
    EXECUTE format('DROP TABLE staging.%I CASCADE', t);
  END LOOP;
END $$;
