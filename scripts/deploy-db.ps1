<#
.SYNOPSIS
  Applies versioned SQL scripts to a SQL Server database using only sqlcmd.
  Applied scripts are tracked in dbo.schema_version_history (name + SHA-256 checksum).

.NOTES
  - Password is read from the DB_PASSWORD environment variable (never passed as an argument).
  - Scripts are applied in alphabetical order (V001__..., V002__...).
  - Already applied scripts are skipped. If an applied script was modified, the deploy FAILS.
  - Each script should manage its own transaction (BEGIN TRAN / COMMIT) for atomicity.
#>
param(
    [Parameter(Mandatory)] [string] $Server,        # e.g. localhost,14331
    [Parameter(Mandatory)] [string] $Database,      # e.g. AppDb
    [Parameter(Mandatory)] [string] $User,          # e.g. sa
    [Parameter(Mandatory)] [string] $ScriptsPath,   # e.g. db/scripts
    [Parameter(Mandatory)] [string] $Environment    # e.g. DEV / PRD (used for audit only)
)

$ErrorActionPreference = 'Stop'

if (-not $env:DB_PASSWORD) { throw 'DB_PASSWORD environment variable is not set.' }
$env:SQLCMDPASSWORD = $env:DB_PASSWORD   # sqlcmd reads the password from this variable

function Invoke-Sqlcmd-Query {
    param([string] $Db, [string] $Query)
    $out = & sqlcmd -S $Server -U $User -C -d $Db -b -h -1 -W -Q "SET NOCOUNT ON; $Query"
    if ($LASTEXITCODE -ne 0) { throw "sqlcmd failed: $out" }
    return ($out | Out-String).Trim()
}

Write-Host "=== Deploying to [$Environment] $Server / $Database ==="

# 1. Bootstrap: database and history table
Invoke-Sqlcmd-Query -Db 'master' -Query "IF DB_ID(N'$Database') IS NULL CREATE DATABASE [$Database];" | Out-Null

Invoke-Sqlcmd-Query -Db $Database -Query @"
IF OBJECT_ID(N'dbo.schema_version_history') IS NULL
CREATE TABLE dbo.schema_version_history (
    id           INT IDENTITY(1,1) PRIMARY KEY,
    script_name  NVARCHAR(260) NOT NULL UNIQUE,
    checksum     CHAR(64)      NOT NULL,
    environment  NVARCHAR(20)  NOT NULL,
    applied_by   NVARCHAR(128) NOT NULL DEFAULT SUSER_SNAME(),
    applied_on   DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME()
);
"@ | Out-Null

# 2. Apply pending scripts
$files = Get-ChildItem -Path $ScriptsPath -Filter 'V*.sql' | Sort-Object Name
if (-not $files) { throw "No scripts found in $ScriptsPath" }

$applied = 0; $skipped = 0
foreach ($file in $files) {
    $name     = $file.Name
    $checksum = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash
    $existing = Invoke-Sqlcmd-Query -Db $Database -Query "SELECT checksum FROM dbo.schema_version_history WHERE script_name = N'$name';"

    if ($existing) {
        if ($existing -ne $checksum) {
            throw "Script '$name' was already applied but its content has changed. Create a NEW versioned script instead."
        }
        Write-Host "SKIP   $name (already applied)"
        $skipped++
        continue
    }

    Write-Host "APPLY  $name"
    & sqlcmd -S $Server -U $User -C -d $Database -b -i $file.FullName
    if ($LASTEXITCODE -ne 0) { throw "Script '$name' failed. Deployment aborted." }

    Invoke-Sqlcmd-Query -Db $Database -Query "INSERT INTO dbo.schema_version_history (script_name, checksum, environment) VALUES (N'$name', '$checksum', N'$Environment');" | Out-Null
    $applied++
}

Write-Host "=== Done. Applied: $applied | Skipped: $skipped ==="
