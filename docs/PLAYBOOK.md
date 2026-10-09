# Playbook: Automated SQL Server Deployments (GitHub + Azure DevOps)

Living document. Built while running the lab; goal is a repeatable guide for new clients.
Status: DRAFT - sections marked TODO are completed as the lab progresses.

## 1. Target scenario

- DEV and HML are two databases in the same SQL Server instance (server A).
- PRD is in another server (server B).
- Developers work directly in DEV (outside the pipeline).
- The pipeline deploys to HML automatically and to PRD after a manual approval.
- Databases already exist; only changes from now on are versioned (see 4. Baseline).
- Plain `.sql` scripts, `sqlcmd` and PowerShell. No migration tool.

## 2. Components

| Component | Role |
|---|---|
| GitHub repo | Source of truth: `db/scripts/V###__description.sql` |
| Azure DevOps Pipeline | Orchestrates stages HML -> PRD (YAML in the repo) |
| Self-hosted agent, server A | Runs the HML deployment; reaches the HML database |
| Self-hosted agent, server B | Runs the PRD deployment; reaches the PRD database |
| `scripts/deploy-db.ps1` | Applies pending scripts, tracks them in `dbo.schema_version_history` |
| Azure DevOps Environments | `hml`, `prd` (approval check on `prd`) |
| Variable groups | One secret `DB_PASSWORD` per environment |

## 3. Prerequisites per client

Azure DevOps free tier is enough (1 self-hosted parallel job, unlimited minutes; stages are sequential).
Confirm in Organization settings > Parallel jobs.

On each server that hosts an agent:
- `sqlcmd` (go-sqlcmd, `winget install sqlcmd`) installed for ALL users (system PATH)
- Git
- PowerShell 5.1+
- Outbound HTTPS (443) to `dev.azure.com`, `github.com` and related Microsoft/GitHub domains
- A dedicated deployment SQL login with least privilege (the lab uses `sa` only for convenience)

## 4. Baseline for existing databases (TODO)

HML and PRD must be identical before the first pipeline run; only new changes get scripts.

## 5. Setup steps (as executed in the lab)

1. GitHub: private repository, push the project (`.gitignore` blocks `.env`, PAT files, agent folders).
2. Azure DevOps: organization + private project.
3. Verify parallel jobs (self-hosted = 1).
4. Install `sqlcmd` and Git on the machine(s) that host agents.
5. Start the database(s). Test connection with `sqlcmd`.
6. Test `deploy-db.ps1` manually against a non-production database first.
7. Agent pools: one per environment (`pool-hml`, `pool-prd`).
8. PAT with scope Agent Pools (Read & manage), short expiration; used once to register agents.
9. Install each agent in its own folder, register in its pool, run as a service in real servers.
10. Variable groups with secret `DB_PASSWORD` per environment; environments with approval on `prd`.
11. Create the pipeline from the existing YAML (GitHub App authorizes only the selected repository).
12. First run: permit pipeline access to each resource (pools, groups, environments) when prompted.

TODO: HML/PRD adaptation steps, developer flow, failure tests.

## 6. Lessons learned (problems found and fixes)

| # | Problem | Cause | Fix |
|---|---|---|---|
| 1 | `sqlcmd` not recognized | Not installed; it is not part of Docker or the SQL Server image | `winget install sqlcmd`; open a NEW terminal so PATH refreshes |
| 2 | Deploy failed: "script was already applied but its content has changed" with an unchanged file | The checksum is over file bytes. `core.autocrlf=true` on the agent checkout turned LF into CRLF (289 vs 300 bytes, different SHA-256) | Add `.gitattributes` with `*.sql text eol=lf` |
| 3 | Same error persisted after the fix | Git does not rewrite unchanged files when only attributes change, and the agent reuses its work folder | Delete the agent work folder once (`_work\<n>\s`), or use `clean: true` on checkout |
| 4 | Pipeline waits for resources | First use of pools, variable groups and environments needs explicit permission | Click View > Permit when prompted |

Process rules that follow from these:
- Never edit a script after it was applied; create the next version.
- Keep SQL line endings fixed with `.gitattributes`.
- Install tools machine-wide, not per user, on servers where the agent runs as a service.

## 7. Developer journey (TODO)

## 8. Controls and risks (TODO)

Known risk: drift when someone changes HML/PRD outside the pipeline.

## 9. Evidence checklist (TODO)
