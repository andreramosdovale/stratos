-- Cruzamento dos dois datasets: notícias por município e ano, ao lado dos
-- homicídios registrados e dos indicadores de infraestrutura.
WITH noticias_mun AS (
  SELECT nm.municipio_id,
         extract(year FROM n.data_publicacao)::smallint AS ano,
         count(DISTINCT n.id)                           AS noticias,
         count(DISTINCT hn.id)                          AS homicidios_noticiados
  FROM noticias.noticia_municipio nm
  JOIN noticias.noticia n ON n.id = nm.noticia_id
  LEFT JOIN noticias.homicidio_noticiado hn ON hn.noticia_id = n.id
  GROUP BY nm.municipio_id, ano
)
SELECT
  m.nome                                      AS municipio,
  nm.ano,
  nm.noticias,
  nm.homicidios_noticiados,
  (SELECT sum(h.quantidade) FROM infraestrutura.homicidio h
    WHERE h.municipio_id = m.id AND h.ano = nm.ano)            AS homicidios_registrados,
  (SELECT jsonb_object_agg(i.codigo, mi.valor)
     FROM infraestrutura.medicao_indicador mi
     JOIN infraestrutura.indicador i ON i.id = mi.indicador_id
    WHERE mi.municipio_id = m.id AND mi.ano = nm.ano)          AS indicadores
FROM noticias_mun nm
JOIN nucleo.municipio m ON m.id = nm.municipio_id
ORDER BY m.nome, nm.ano;
