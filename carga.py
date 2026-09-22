"""Carga dos CSVs no banco.

    python carga.py <nucleo|infraestrutura|noticias|todos> [--dir dados]

Cada conjunto é gravado numa única transação. Quem valida é o próprio banco
(NOT NULL, CHECK, UNIQUE, FK): se uma linha for recusada, o script mostra
arquivo, linha e motivo, e nada daquele conjunto é gravado.
"""

import argparse
import csv
import hashlib
import json
import sys
from pathlib import Path

import psycopg

RAIZ = Path(__file__).resolve().parent
PROVENIENCIA = "origem, modelo_llm, validado_por_humano, validado_em, lote_carga_id"


class Carga:
    def __init__(self, cur, pasta, conjunto):
        self.cur = cur
        self.pasta = pasta
        self.onde = ""
        self.ids = {}
        arquivos = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(pasta.glob("*.csv"))}
        self.lote = self.um("INSERT INTO nucleo.lote_carga (conjunto, arquivos) VALUES (%s, %s) RETURNING id",
                            conjunto, json.dumps(arquivos))

    def linhas(self, arquivo):
        """Percorre o CSV; campos vazios viram None."""
        with open(self.pasta / arquivo, encoding="utf-8-sig", newline="") as f:
            for n, linha in enumerate(csv.DictReader(f), start=2):
                self.onde = f"{arquivo}:{n}"
                yield {k: (v.strip() or None) for k, v in linha.items()}

    def sql(self, comando, *valores):
        self.cur.execute(comando, valores)

    def um(self, comando, *valores):
        linha = self.cur.execute(comando, valores).fetchone()
        return linha[0] if linha else None

    def id(self, tabela, coluna, valor):
        """id da linha de `tabela` em que `coluna` = valor (None se valor vazio)."""
        if valor is None:
            return None
        chave = (tabela, coluna, valor)
        if chave not in self.ids:
            self.ids[chave] = self.um(f"SELECT id FROM {tabela} WHERE {coluna} = %s", valor)
            if self.ids[chave] is None:
                raise ValueError(f"{coluna} não encontrado em {tabela}: {valor}")
        return self.ids[chave]

    def municipio(self, codigo_ibge):
        return self.id("nucleo.municipio", "codigo_ibge", codigo_ibge)

    def faccao(self, nome):
        if nome:
            self.sql("INSERT INTO nucleo.faccao (nome) VALUES (%s) ON CONFLICT DO NOTHING", nome)
        return self.id("nucleo.faccao", "nome", nome)

    def pessoa(self, r):
        if not r["pessoa_nome"]:
            return None
        chave = r["pessoa_chave"] or r["pessoa_nome"]
        self.sql("INSERT INTO nucleo.pessoa (chave_origem, nome) VALUES (%s, %s) ON CONFLICT DO NOTHING",
                 chave, r["pessoa_nome"])
        return self.id("nucleo.pessoa", "chave_origem", chave)

    def proveniencia(self, r):
        return (r["origem"], r["modelo_llm"], r["validado_por_humano"] or "false", r["validado_em"], self.lote)


def lista(texto):
    return [item.strip() for item in (texto or "").split("|") if item.strip()]


def nucleo(c):
    for r in c.linhas("municipios.csv"):
        c.sql("INSERT INTO nucleo.municipio (codigo_ibge, nome, uf_id) VALUES (%s, %s, %s)",
              r["codigo_ibge"], r["nome"], c.id("nucleo.uf", "sigla", r["uf"]))
    for r in c.linhas("fontes.csv"):
        c.sql("INSERT INTO nucleo.fonte_dado (nome, descricao, url) VALUES (%s, %s, %s)",
              r["nome"], r["descricao"], r["url"])


def infraestrutura(c):
    fonte = lambda r: c.id("nucleo.fonte_dado", "nome", r["fonte"])

    for r in c.linhas("homicidios.csv"):
        c.sql("""INSERT INTO infraestrutura.homicidio (municipio_id, ano, quantidade, fonte_dado_id, lote_carga_id)
                 VALUES (%s, %s, %s, %s, %s)""",
              c.municipio(r["codigo_ibge"]), r["ano"], r["quantidade"], fonte(r), c.lote)
    for r in c.linhas("indicadores.csv"):
        c.sql("INSERT INTO infraestrutura.indicador (codigo, eixo, nome, unidade, descricao) VALUES (%s, %s, %s, %s, %s)",
              r["codigo"], r["eixo"], r["nome"], r["unidade"], r["descricao"])
    for r in c.linhas("medicoes.csv"):
        c.sql("""INSERT INTO infraestrutura.medicao_indicador
                 (municipio_id, ano, indicador_id, valor, fonte_dado_id, lote_carga_id) VALUES (%s, %s, %s, %s, %s, %s)""",
              c.municipio(r["codigo_ibge"]), r["ano"], c.id("infraestrutura.indicador", "codigo", r["indicador"]),
              r["valor"], fonte(r), c.lote)
    for r in c.linhas("bancos.csv"):
        c.sql("INSERT INTO infraestrutura.banco_desenvolvimento (sigla, nome, abrangencia) VALUES (%s, %s, %s)",
              r["sigla"], r["nome"], r["abrangencia"])
    for r in c.linhas("projetos.csv"):
        projeto = c.um("""INSERT INTO infraestrutura.projeto_financiado
                          (codigo_origem, banco_id, titulo, eixo, valor_contratado, data_contratacao, situacao,
                           fonte_dado_id, lote_carga_id)
                          VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s) RETURNING id""",
                       r["codigo_origem"], c.id("infraestrutura.banco_desenvolvimento", "sigla", r["banco"]),
                       r["titulo"], r["eixo"], r["valor_contratado"], r["data_contratacao"], r["situacao"],
                       fonte(r), c.lote)
        for codigo in set(lista(r["municipios"])):
            c.sql("INSERT INTO infraestrutura.projeto_municipio VALUES (%s, %s)", projeto, c.municipio(codigo))


def noticias(c):
    for r in c.linhas("noticias.csv"):
        c.sql("INSERT INTO nucleo.veiculo_imprensa (nome) VALUES (%s) ON CONFLICT DO NOTHING", r["veiculo"])
        c.sql("""INSERT INTO noticias.noticia (codigo_origem, veiculo_id, url, titulo, data_publicacao, resumo, lote_carga_id)
                 VALUES (%s, %s, %s, %s, %s, %s, %s)""",
              r["id_noticia"], c.id("nucleo.veiculo_imprensa", "nome", r["veiculo"]), r["url"], r["titulo"],
              r["data_publicacao"], r["resumo"], c.lote)

    def eixo(arquivo, tabela, colunas, valores):
        """Um arquivo de eixo: id_noticia + colunas próprias + proveniência. Devolve os ids inseridos."""
        marcadores = ", ".join(["%s"] * (len(colunas) + 6))
        comando = f"INSERT INTO {tabela} (noticia_id, {', '.join(colunas)}, {PROVENIENCIA}) VALUES ({marcadores})"
        for r in c.linhas(arquivo):
            noticia = c.id("noticias.noticia", "codigo_origem", r["id_noticia"])
            c.sql(comando, noticia, *valores(r), *c.proveniencia(r))
            yield r, noticia

    def gravar(*args):
        for _ in eixo(*args):
            pass

    gravar("noticia_municipios.csv", "noticias.noticia_municipio", ["municipio_id"],
           lambda r: [c.municipio(r["codigo_ibge"])])
    gravar("noticia_pessoas.csv", "noticias.noticia_pessoa", ["pessoa_id", "papel"],
           lambda r: [c.pessoa(r), r["papel"]])
    gravar("homicidios_noticiados.csv", "noticias.homicidio_noticiado",
           ["municipio_id", "data_fato", "qtd_vitimas", "meio_empregado", "motivacao"],
           lambda r: [c.municipio(r["codigo_ibge"]), r["data_fato"], r["qtd_vitimas"], r["meio_empregado"], r["motivacao"]])
    gravar("estrutura_faccional.csv", "noticias.estrutura_faccional", ["faccao_id", "pessoa_id", "cargo_funcao", "descricao"],
           lambda r: [c.faccao(r["faccao"]), c.pessoa(r), r["cargo_funcao"], r["descricao"]])
    for r, noticia in eixo("disputas_territoriais.csv", "noticias.disputa_territorial",
                           ["municipio_id", "territorio", "descricao"],
                           lambda r: [c.municipio(r["codigo_ibge"]), r["territorio"], r["descricao"]]):
        # a disputa acabou de ser inserida: é a de maior id da notícia
        disputa = c.um("SELECT max(id) FROM noticias.disputa_territorial WHERE noticia_id = %s", noticia)
        for nome in set(lista(r["faccoes"])):
            c.sql("INSERT INTO noticias.disputa_faccao VALUES (%s, %s)", disputa, c.faccao(nome))
    gravar("relacoes_faccionais.csv", "noticias.relacao_faccional", ["faccao_a_id", "faccao_b_id", "tipo", "descricao"],
           lambda r: [c.faccao(r["faccao_a"]), c.faccao(r["faccao_b"]), r["tipo"], r["descricao"]])
    gravar("lavagem_dinheiro.csv", "noticias.lavagem_dinheiro", ["faccao_id", "mecanismo", "valor_estimado", "descricao"],
           lambda r: [c.faccao(r["faccao"]), r["mecanismo"], r["valor_estimado"], r["descricao"]])
    gravar("atividades_ilicitas.csv", "noticias.atividade_ilicita", ["faccao_id", "tipo", "descricao"],
           lambda r: [c.faccao(r["faccao"]), r["tipo"], r["descricao"]])
    gravar("atuacao_politica.csv", "noticias.atuacao_politica", ["faccao_id", "pessoa_id", "cargo", "descricao"],
           lambda r: [c.faccao(r["faccao"]), c.pessoa(r), r["cargo"], r["descricao"]])
    gravar("operacoes_policiais.csv", "noticias.operacao_policial",
           ["codigo_origem", "nome_operacao", "orgao", "municipio_id", "data_operacao", "qtd_presos", "qtd_mortos"],
           lambda r: [r["id_operacao"], r["nome_operacao"], r["orgao"], c.municipio(r["codigo_ibge"]),
                      r["data_operacao"], r["qtd_presos"], r["qtd_mortos"]])

    def operacao(r):
        if not r["id_operacao"]:
            return None
        op = c.um("""SELECT o.id FROM noticias.operacao_policial o JOIN noticias.noticia n ON n.id = o.noticia_id
                     WHERE n.codigo_origem = %s AND o.codigo_origem = %s""", r["id_noticia"], r["id_operacao"])
        if op is None:
            raise ValueError(f"id_operacao não encontrado para a notícia {r['id_noticia']}: {r['id_operacao']}")
        return op

    gravar("apreensoes.csv", "noticias.apreensao",
           ["operacao_id", "municipio_id", "item", "quantidade", "unidade", "descricao"],
           lambda r: [operacao(r), c.municipio(r["codigo_ibge"]), r["item"], r["quantidade"], r["unidade"], r["descricao"]])


CONJUNTOS = {"nucleo": nucleo, "infraestrutura": infraestrutura, "noticias": noticias}


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description="Carga dos CSVs no banco")
    parser.add_argument("conjunto", choices=[*CONJUNTOS, "todos"])
    parser.add_argument("--dir", default=str(RAIZ / "dados"), help="pasta com um subdiretório por conjunto")
    args = parser.parse_args()

    senha = next(l.split("=", 1)[1].strip() for l in (RAIZ / ".env").read_text(encoding="utf-8").splitlines()
                 if l.startswith("POSTGRES_PASSWORD="))
    with psycopg.connect(host="127.0.0.1", dbname="invips", user="postgres", password=senha) as conn:
        for conjunto in (CONJUNTOS if args.conjunto == "todos" else [args.conjunto]):
            pasta = Path(args.dir) / conjunto
            carga = None
            try:
                with conn.transaction(), conn.cursor() as cur:
                    carga = Carga(cur, pasta, conjunto)
                    CONJUNTOS[conjunto](carga)
            except (psycopg.Error, ValueError) as erro:
                diag = getattr(erro, "diag", None)
                motivo = " ".join(filter(None, [diag.message_primary, diag.message_detail])) if diag else str(erro)
                sys.exit(f"{conjunto}: {carga.onde if carga else ''}: {motivo}\nNada de \"{conjunto}\" foi gravado.")
            print(f"{conjunto}: carregado (lote {carga.lote})")


if __name__ == "__main__":
    main()
