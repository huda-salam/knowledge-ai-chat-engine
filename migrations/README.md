# Database migrations

Migrations are plain SQL and are intentionally kept independent of a Go migration library. This keeps the schema portable and avoids coupling the domain to a migration framework.

Apply migrations in filename order with the PostgreSQL client or a deployment migration runner.

Local database:

```bash
docker compose up -d postgres
psql postgresql://knowledge:knowledge_dev@localhost:5432/knowledge_ai -f migrations/000001_initial_schema.sql
```

The initial schema provides the relational source of record and PostgreSQL full-text search. Vector search is intentionally not enabled yet.
