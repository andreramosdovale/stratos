# Banco de dados do INViPS

PostgreSQL em Docker para os datasets Homicídios × Infraestrutura e Notícias.
Desenho completo em [`spec-banco-postgres-docker.md`](spec-banco-postgres-docker.md).

```bash
cp .env.example .env                # defina POSTGRES_PASSWORD
docker compose up -d --wait         # na 1ª vez, o Postgres executa db/init/*.sql
pip install -r requirements.txt
python carga.py todos --dir dados/exemplo   # sem --dir, lê ./dados/<conjunto>/
```

Conectar: `psql -h 127.0.0.1 -U postgres -d invips` (senha do `.env`).

- Formato dos CSVs: [`dados/README.md`](dados/README.md)
- Modelo: [`docs/MER.md`](docs/MER.md) e [`docs/DICIONARIO-DADOS.md`](docs/DICIONARIO-DADOS.md)
- Consultas de referência: `db/consultas/`

**Mudar a estrutura:** aplique o `ALTER` no banco e faça a mesma mudança em
`db/init/`, para que um banco criado do zero saia igual. `db/init/` só roda
quando o volume é criado (`docker compose down -v` apaga o volume e os dados).
