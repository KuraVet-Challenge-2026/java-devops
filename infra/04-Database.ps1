# =====================================================================
# 04-Database.ps1
# Cria o SQL Server, o banco de dados e a regra de firewall para
# servicos do Azure. Idempotente: cada recurso e checado antes de
# criar. A senha do admin nunca fica neste arquivo - veja
# Get-SqlPassword em 00-Variaveis.ps1.
# =====================================================================

. "$PSScriptRoot\00-Variaveis.ps1"

az group show -n $global:RG --output none 2>$null
Assert-ComandoOk "Resource Group $($global:RG) nao existe. Rode 01-ResourceGroup.ps1 primeiro."

# --- SQL Server ---------------------------------------------------
az sql server show -n $global:SQLSERVER -g $global:RG --output none 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "OK - SQL Server $($global:SQLSERVER) ja existe. Nada a fazer." -ForegroundColor Green
} else {
    $senha = Get-SqlPassword
    Write-Host ">>> Criando SQL Server $($global:SQLSERVER) em $($global:LOCAL)..." -ForegroundColor Cyan
    az sql server create -n $global:SQLSERVER -g $global:RG -l $global:LOCAL --admin-user $global:SQLUSER --admin-password $senha --output none
    Assert-ComandoOk "Falha ao criar o SQL Server $($global:SQLSERVER). Rode .\00-Preflight.ps1 para checar a regiao (RegionDoesNotAllowProvisioning)."
    Write-Host "OK - SQL Server $($global:SQLSERVER) criado." -ForegroundColor Green
}

# --- Banco de dados -------------------------------------------------
az sql db show -g $global:RG --server $global:SQLSERVER -n $global:SQLDB --output none 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "OK - Banco de dados $($global:SQLDB) ja existe. Nada a fazer." -ForegroundColor Green
} else {
    Write-Host ">>> Criando banco de dados $($global:SQLDB)..." -ForegroundColor Cyan
    az sql db create -g $global:RG --server $global:SQLSERVER -n $global:SQLDB --service-objective Basic --output none
    Assert-ComandoOk "Falha ao criar o banco de dados $($global:SQLDB)."
    Write-Host "OK - Banco de dados $($global:SQLDB) criado." -ForegroundColor Green
}

# --- Regra de firewall (servicos do Azure) --------------------------
az sql server firewall-rule show -g $global:RG --server $global:SQLSERVER -n AllowAzureServices --output none 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "OK - Regra de firewall AllowAzureServices ja existe. Nada a fazer." -ForegroundColor Green
} else {
    Write-Host ">>> Criando regra de firewall AllowAzureServices..." -ForegroundColor Cyan
    az sql server firewall-rule create -g $global:RG --server $global:SQLSERVER -n AllowAzureServices --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0 --output none
    Assert-ComandoOk "Falha ao criar a regra de firewall AllowAzureServices."
    Write-Host "OK - Regra de firewall AllowAzureServices criada." -ForegroundColor Green
}
