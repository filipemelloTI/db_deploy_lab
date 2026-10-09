---
applyTo: "db/scripts/**/*.sql"
---

# Review rules for SQL Server deployment scripts

Scripts run with `sqlcmd` against SQL Server, first in HML and then in PRD.

## Required structure
- The file starts with a comment stating the type (`DDL` or `DML`) and what the script does.
- The changes are wrapped in `BEGIN TRAN;` ... `COMMIT;` so a failure rolls everything back.
- One logical change per script.
- No `USE <database>` and no hard-coded database or server names: the pipeline chooses the target.

## Flag as high risk
- `DROP TABLE`, `DROP COLUMN`, `DROP DATABASE`, `TRUNCATE TABLE`.
- `DELETE` or `UPDATE` without a `WHERE` clause.
- `ALTER COLUMN` that shrinks a type or turns a nullable column into `NOT NULL` without a default or
  data fix. Ask what happens to existing rows.
- Adding a `NOT NULL` column without a `DEFAULT` to a table that may already have data.
- Creating indexes or altering large tables (possible long locks); ask about volume and timing.
- Changes to permissions, logins or server-level objects.
- `SELECT *` inside views or procedures.

## Flag as medium risk
- Missing or unclear names for constraints and indexes (prefer `PK_`, `FK_`, `IX_`, `DF_` prefixes).
- A foreign key to a table or column that is not created in an earlier script.
- `CREATE` of an object that may already exist in HML/PRD (suggest `CREATE OR ALTER` for views,
  functions and procedures).
- DML that is not safe to read as idempotent where it matters (duplicate inserts).
- Dynamic SQL built by string concatenation.

## Do not
- Do not suggest adding `GO` batches inside the `BEGIN TRAN` block unless required; `GO` ends the
  batch and can leave a transaction open.
- Do not ask for a migration framework or any new tool: plain SQL scripts are a deliberate choice.
