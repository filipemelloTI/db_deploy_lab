# Repository context for code review

This repository holds versioned SQL Server scripts (DDL and DML) that an Azure DevOps pipeline deploys
to HML automatically and to PRD after a manual approval. Developers test changes in DEV first, outside
this repository.

## How the repository works
- Every change to a database is a new file in `db/scripts/` named `V<3 digits>__<verb>_<object>.sql`
  (example: `V004__create_orders_table.sql`). Files run in alphabetical order.
- `scripts/deploy-db.ps1` stores each applied script name and SHA-256 checksum in
  `dbo.schema_version_history`. A script that was already applied must never change.
- `azure-pipelines.yml` defines the HML -> PRD flow. Changes to it deserve extra attention.

## What to flag in a pull request
- Any modification or deletion of an existing file in `db/scripts/`. Applied scripts are immutable;
  the fix must be a new, higher-numbered script. (Exception: a script that never ran successfully.)
- A new script whose number is not the next in the sequence, a duplicated number, or a name that does
  not follow the convention.
- Credentials, passwords, tokens, connection strings or hard-coded server/database names anywhere.
- Changes to `scripts/deploy-db.ps1` or `azure-pipelines.yml` that weaken a control: removing the
  checksum check, the approval stage, `-b` (stop on error), or re-enabling pull request triggers.

## How to write the review
- Be concise. Start with a one-line summary and a verdict: APPROVE, REVIEW or REJECT.
- Quote the file and line for each finding and say why it matters in production.
- Do not comment on formatting preferences unless they break the conventions above.
- SQL-specific rules are in `.github/instructions/sql-scripts.instructions.md`.
