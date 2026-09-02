# =====================================================================
# 02-AppServicePlan.ps1
# Cria o App Service Plan Linux. Idempotente: se ja existir, so
# informa e segue. Exige que o Resource Group (01) ja exista.
# =====================================================================

. "$PSScriptRoot\00-Variaveis.ps1"

az group show -n $global:RG --output none 2>$null
Assert-ComandoOk "Resource Group $($global:RG) nao existe. Rode 01-ResourceGroup.ps1 primeiro."

az appservice plan show -n $global:PLANO -g $global:RG --output none 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "OK - App Service Plan $($global:PLANO) ja existe. Nada a fazer." -ForegroundColor Green
} else {
    Write-Host ">>> Criando App Service Plan $($global:PLANO) (SKU $($global:SKU)) em $($global:LOCAL)..." -ForegroundColor Cyan
    az appservice plan create -n $global:PLANO -g $global:RG --is-linux --sku $global:SKU --location $global:LOCAL --output none
    Assert-ComandoOk "Falha ao criar o App Service Plan $($global:PLANO). Rode .\00-Preflight.ps1 para diagnosticar cota/SKU/regiao."
    Write-Host "OK - App Service Plan $($global:PLANO) criado." -ForegroundColor Green
}
