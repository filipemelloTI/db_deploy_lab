# Request for Approval: Database Deployment Automation Proof of Concept

**Requester:** <your name>
**Date:** <date>
**Subject:** Approval to use GitHub and Azure DevOps (free tier) for a proof of concept of automated DDL/DML deployment to SQL Server

## 1. Purpose
Evaluate an automated, auditable process to deploy DDL and DML scripts to SQL Server
through a CI/CD pipeline, replacing manual script execution.

## 2. Scope
- Two isolated SQL Server instances (DEV and PRD) running in containers.
  No production or customer data is involved.
- Source control in GitHub; orchestration in Azure DevOps Pipelines.
- Plain SQL scripts executed with `sqlcmd`. No third-party migration tools.
- Self-hosted agents only (no Microsoft-hosted agents, no data leaves the local environment).

## 3. Cost
No cost. Azure DevOps free tier is used (up to 5 Basic users, 1 self-hosted parallel job
with unlimited minutes). GitHub free tier is used.

## 4. How it works
1. A developer opens a Pull Request with a new versioned script (`V004__create_orders_table.sql`).
2. After review, the PR is merged into `main`.
3. The Azure DevOps pipeline starts automatically and deploys to DEV.
4. A designated approver reviews the DEV result and approves the PRD stage.
5. The pipeline deploys to PRD.
6. Every applied script is recorded in `dbo.schema_version_history`
   (script name, SHA-256 checksum, environment, user, timestamp).

## 5. Controls
| Control | Implementation |
|---|---|
| Peer review | `main` branch protected; Pull Request required |
| Segregation of environments | Separate containers, networks, credentials, agent pools |
| Approval gate | Manual approval on the `prd` Azure DevOps Environment |
| Secrets management | Passwords stored as secret variables in Variable Groups |
| Immutability | Deploy fails if an already applied script is modified |
| Fail-fast | Any SQL error aborts the deployment; PRD never runs after a DEV failure |
| Audit trail | Pipeline run history + `dbo.schema_version_history` table |

## 6. Data and security considerations
- Only synthetic test data is used.
- Credentials are never stored in the repository or passed on command lines.
- Agents run on an internal VM and connect outbound to Azure DevOps over HTTPS (port 443).
- A dedicated least-privilege deployment login will replace `sa` if the PoC moves forward.

## 7. Evidence of the PoC (to be attached)
- [ ] Screenshot: both SQL Server containers running
- [ ] Screenshot: agents online in `pool-dev` and `pool-prd`
- [ ] Screenshot: successful DEV stage log
- [ ] Screenshot: PRD approval request and approved run
- [ ] Screenshot: `schema_version_history` query result in DEV and PRD
- [ ] Screenshot: failed run when an applied script is modified
- [ ] Screenshot: failed DEV run blocking PRD

## 8. Requested approvals
- Use of a GitHub private repository for database scripts.
- Use of an Azure DevOps organization (free tier) for the pipeline.
- Installation of the Azure Pipelines agent on the lab VM.

## 9. Attachments
- `README.md` (architecture and setup guide)
- `azure-pipelines.yml`, `scripts/deploy-db.ps1`, `docker-compose.yml`, sample scripts in `db/scripts/`
