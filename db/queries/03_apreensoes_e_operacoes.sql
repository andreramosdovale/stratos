-- Apreensões (por tipo de item) e operações policiais por município e ano.
SELECT
  m.nome                                          AS municipio,
  extract(year FROM n.data_publicacao)::int       AS ano,
  a.item,
  a.unidade,
  count(*)                                        AS registros,
  sum(a.quantidade)                               AS quantidade_total,
  count(DISTINCT a.operacao_id)                   AS operacoes
FROM noticias.apreensao a
JOIN noticias.noticia n ON n.id = a.noticia_id
LEFT JOIN nucleo.municipio m ON m.id = a.municipio_id
GROUP BY m.nome, ano, a.item, a.unidade
ORDER BY m.nome NULLS LAST, ano, a.item;
