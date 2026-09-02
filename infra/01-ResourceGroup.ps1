# =====================================================================
# 01-ResourceGroup.ps1
# Cria o Resource Group do projeto. Idempotente: se ja existir, so
# informa e segue.
# =====================================================================

. "$PSScriptRoot\00-Variaveis.ps1"

$existe = az group exists -n $global:RG
Assert-ComandoOk "Falha ao verificar se o Resource Group $($global:RG) existe."

if ($existe -eq "true") {
    Write-Host "OK - Resource Group $($global:RG) ja existe. Nada a fazer." -ForegroundColor Green
} else {
    Write-Host ">>> Criando Resource Group $($global:RG) em $($global:LOCAL)..." -ForegroundColor Cyan
    az group create -n $global:RG -l $global:LOCAL --output none
    Assert-ComandoOk "Falha ao criar o Resource Group $($global:RG)."
    Write-Host "OK - Resource Group $($global:RG) criado." -ForegroundColor Green
}
