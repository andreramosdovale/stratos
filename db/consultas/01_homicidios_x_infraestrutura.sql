-- Homicídios por município e ano, com os indicadores de cada eixo de
-- infraestrutura e os projetos financiados contratados até aquele ano.
SELECT
  uf.sigla                                  AS uf,
  m.nome                                    AS municipio,
  h.ano,
  sum(h.quantidade)                         AS homicidios,
  (SELECT jsonb_object_agg(i.codigo, mi.valor)
     FROM infraestrutura.medicao_indicador mi
     JOIN infraestrutura.indicador i ON i.id = mi.indicador_id
    WHERE mi.municipio_id = m.id AND mi.ano = h.ano)          AS indicadores,
  (SELECT count(*)
     FROM infraestrutura.projeto_municipio pm
     JOIN infraestrutura.projeto_financiado p ON p.id = pm.projeto_id
    WHERE pm.municipio_id = m.id
      AND extract(year FROM p.data_contratacao) <= h.ano)     AS projetos_contratados
FROM infraestrutura.homicidio h
JOIN nucleo.municipio m ON m.id = h.municipio_id
JOIN nucleo.uf uf ON uf.id = m.uf_id
GROUP BY uf.sigla, m.id, m.nome, h.ano
ORDER BY uf.sigla, m.nome, h.ano;
