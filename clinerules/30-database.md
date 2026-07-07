# Database Standards

Database:

Percona XtraDB (MySQL)

Use Ecto.

Always:

- Use indexes when appropriate.
- Avoid N+1 queries.
- Preload associations explicitly.
- Use transactions when modifying multiple tables.

Never:

SELECT \*

Always select required fields.

Large updates:

Use Repo.update_all where appropriate.

Large inserts:

Use insert_all when appropriate.

Prefer migrations that are reversible.
