-- Por facção e ano de publicação: notícias em que aparece, disputas
-- territoriais, confrontos e alianças.
WITH presenca AS (
            SELECT ef.faccao_id, ef.noticia_id, 'estrutura' AS fato FROM noticias.estrutura_faccional ef
  UNION ALL SELECT df.faccao_id, d.noticia_id, 'disputa' FROM noticias.disputa_faccao df
            JOIN noticias.disputa_territorial d ON d.id = df.disputa_id
  UNION ALL SELECT r.faccao_a_id, r.noticia_id, r.tipo FROM noticias.relacao_faccional r
  UNION ALL SELECT r.faccao_b_id, r.noticia_id, r.tipo FROM noticias.relacao_faccional r
  UNION ALL SELECT l.faccao_id, l.noticia_id, 'lavagem' FROM noticias.lavagem_dinheiro l WHERE l.faccao_id IS NOT NULL
  UNION ALL SELECT a.faccao_id, a.noticia_id, 'atividade' FROM noticias.atividade_ilicita a WHERE a.faccao_id IS NOT NULL
)
SELECT
  f.nome                                              AS faccao,
  extract(year FROM n.data_publicacao)::int           AS ano,
  count(DISTINCT p.noticia_id)                        AS noticias,
  count(*) FILTER (WHERE p.fato = 'disputa')          AS disputas,
  count(*) FILTER (WHERE p.fato = 'confronto')        AS confrontos,
  count(*) FILTER (WHERE p.fato = 'alianca')          AS aliancas
FROM presenca p
JOIN nucleo.faccao f ON f.id = p.faccao_id
JOIN noticias.noticia n ON n.id = p.noticia_id
GROUP BY f.nome, ano
ORDER BY f.nome, ano;
