-- V4: trilha de auditoria de escrita (RF-7).
-- A função de trigger é SECURITY DEFINER (dona: invips_admin), então quem
-- escreve nos dados não precisa, e não tem, permissão de escrita no log.

CREATE TABLE auditoria.log_alteracao (
  id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  tabela          text NOT NULL,
  operacao        text NOT NULL CHECK (operacao IN ('INSERT', 'UPDATE', 'DELETE')),
  chave           jsonb NOT NULL,
  dados_antigos   jsonb,
  dados_novos     jsonb,
  usuario         text NOT NULL DEFAULT session_user,
  transacao       bigint NOT NULL DEFAULT txid_current(),
  ocorrido_em     timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE auditoria.log_alteracao IS 'Registro de toda escrita nas tabelas dos esquemas de dados. Somente leitura para o curador.';
COMMENT ON COLUMN auditoria.log_alteracao.id IS 'Identificador interno.';
COMMENT ON COLUMN auditoria.log_alteracao.tabela IS 'Tabela alterada (esquema.tabela).';
COMMENT ON COLUMN auditoria.log_alteracao.operacao IS 'INSERT, UPDATE ou DELETE.';
COMMENT ON COLUMN auditoria.log_alteracao.chave IS 'Chave primária da linha alterada.';
COMMENT ON COLUMN auditoria.log_alteracao.dados_antigos IS 'Linha antes da alteração (UPDATE/DELETE).';
COMMENT ON COLUMN auditoria.log_alteracao.dados_novos IS 'Linha depois da alteração (INSERT/UPDATE).';
COMMENT ON COLUMN auditoria.log_alteracao.usuario IS 'Usuário da sessão que fez a alteração.';
COMMENT ON COLUMN auditoria.log_alteracao.transacao IS 'Identificador da transação.';
COMMENT ON COLUMN auditoria.log_alteracao.ocorrido_em IS 'Início da transação que fez a alteração.';
CREATE INDEX ON auditoria.log_alteracao (tabela, ocorrido_em);

CREATE FUNCTION auditoria.registrar() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, pg_temp AS $$
DECLARE
  linha jsonb := to_jsonb(CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END);
  chave jsonb := '{}';
  coluna text;
BEGIN
  -- TG_ARGV traz os nomes das colunas da chave primária
  FOREACH coluna IN ARRAY TG_ARGV LOOP
    chave := chave || jsonb_build_object(coluna, linha -> coluna);
  END LOOP;

  INSERT INTO auditoria.log_alteracao (tabela, operacao, chave, dados_antigos, dados_novos)
  VALUES (
    TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME,
    TG_OP,
    chave,
    CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN to_jsonb(OLD) END,
    CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN to_jsonb(NEW) END
  );
  RETURN NULL;
END $$;
COMMENT ON FUNCTION auditoria.registrar() IS 'Trigger AFTER ROW que grava a alteração em auditoria.log_alteracao.';

-- Liga a auditoria numa tabela. Novas migrações devem chamar para cada tabela nova.
CREATE FUNCTION auditoria.habilitar(tabela regclass) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  colunas text;
BEGIN
  SELECT string_agg(quote_literal(a.attname), ', ' ORDER BY k.ord)
    INTO colunas
  FROM pg_index i
  CROSS JOIN LATERAL unnest(i.indkey) WITH ORDINALITY AS k(attnum, ord)
  JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = k.attnum
  WHERE i.indrelid = tabela AND i.indisprimary;

  IF colunas IS NULL THEN
    RAISE EXCEPTION 'tabela % não tem chave primária', tabela;
  END IF;

  EXECUTE format('DROP TRIGGER IF EXISTS auditoria ON %s', tabela);
  EXECUTE format(
    'CREATE TRIGGER auditoria AFTER INSERT OR UPDATE OR DELETE ON %s '
    'FOR EACH ROW EXECUTE FUNCTION auditoria.registrar(%s)', tabela, colunas);
END $$;
COMMENT ON FUNCTION auditoria.habilitar(regclass) IS 'Cria o trigger de auditoria numa tabela, passando as colunas da chave primária.';

SELECT auditoria.habilitar(c.oid)
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname IN ('nucleo', 'infraestrutura', 'noticias')
  AND c.relkind = 'r';
