# Automated SQL Server Deployment Lab (GitHub + Azure DevOps)

Lab that simulates automated deployment of DDL and DML scripts to two separate SQL Server
instances (DEV and PRD), using plain SQL scripts and no third-party migration tool.

## Architecture

```
GitHub repository (db/scripts/*.sql)
        |  merge to main
        v
Azure DevOps Pipeline (azure-pipelines.yml)
        |
        +-- Stage DEV --> agent pool "pool-dev" --> SQL Server DEV (port 14331)
        |
        +-- Stage PRD --> manual approval --> agent pool "pool-prd" --> SQL Server PRD (port 14332)
```

Both containers and both agents run on one Windows VM. They are logically isolated
(separate containers, volumes, Docker networks, agent pools, credentials), which
simulates two different servers.

## Repository structure

| Path | Purpose |
|---|---|
| `docker-compose.yml` | Two independent SQL Server 2022 containers |
| `.env.example` | Template for SA passwords (copy to `.env`) |
| `db/scripts/V###__description.sql` | Versioned DDL/DML scripts |
| `scripts/deploy-db.ps1` | Deployment script (sqlcmd only) |
| `azure-pipelines.yml` | Multi-stage pipeline (DEV, then PRD with approval) |

## How version control works

`deploy-db.ps1` creates the table `dbo.schema_version_history` in the target database.
For each script (alphabetical order):

1. Not in history: run it, then record its name and SHA-256 checksum.
2. In history with same checksum: skip it.
3. In history with different checksum: **fail** (applied scripts are immutable; create a new version).
4. Any sqlcmd error aborts the deployment (`-b` flag) and the PRD stage does not run.

## Naming convention

`V<3-digit version>__<verb>_<object>.sql`, for example `V004__create_orders_table.sql`.
Each script wraps its changes in `BEGIN TRAN ... COMMIT`.

## Setup

### 1. Prerequisites on the VM
- Docker (Desktop or Engine with Linux containers)
- `sqlcmd` (ODBC 18 / go-sqlcmd), available in PATH
- PowerShell 5.1+
- Azure DevOps organization/project and a GitHub repository

### 2. Start the databases
```powershell
Copy-Item .env.example .env      # edit the passwords
docker compose up -d
```

### 3. Self-hosted agents
Download the Azure Pipelines agent and configure **two** agents in separate folders:
```powershell
# folder C:\agents\dev
.\config.cmd --url https://dev.azure.com/<org> --auth pat --token <PAT> --pool pool-dev --agent agent-dev --runAsService
# folder C:\agents\prd
.\config.cmd --url https://dev.azure.com/<org> --auth pat --token <PAT> --pool pool-prd --agent agent-prd --runAsService
```
Create the pools first in *Organization Settings > Agent pools*. The PAT needs the
*Agent Pools (Read & manage)* scope.

### 4. Azure DevOps configuration
1. *Project Settings > Service connections*: create a GitHub connection.
2. *Pipelines > Library*: create variable groups `db-dev-secrets` and `db-prd-secrets`, each with a secret variable `DB_PASSWORD`.
3. *Pipelines > Environments*: create `dev` and `prd`; on `prd` add an **Approvals** check.
4. *Pipelines > New pipeline > GitHub*: select this repository and `azure-pipelines.yml`.

### 5. GitHub configuration
Protect the `main` branch: require Pull Requests before merge.

## Test scenarios

| Scenario | Expected result |
|---|---|
| First run | DEV applies V001-V003; PRD waits for approval, then applies V001-V003 |
| Run again, no changes | All scripts are skipped |
| Add `V004__...sql` | Only V004 is applied in each environment |
| Edit V001 after it was applied | Deploy fails (checksum mismatch) |
| Script with syntax error | DEV fails, PRD stage never starts |

## Manual verification
```powershell
sqlcmd -S localhost,14331 -U sa -C -d AppDb -Q "SELECT * FROM dbo.schema_version_history"
sqlcmd -S localhost,14332 -U sa -C -d AppDb -Q "SELECT * FROM dbo.schema_version_history"
```

## Known limitations of this lab
- Using `sa` is for the lab only; use a dedicated least-privilege deployment login in real environments.
- Running a script and recording it in the history table are two separate steps. A crash between them
  could leave a script applied but unrecorded; keep scripts idempotent where possible.
- No automatic rollback; fix forward with a new versioned script.
