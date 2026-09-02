# =====================================================================
# 03-WebApp.ps1
# Cria o Web App (runtime Java 21 nativo). Idempotente: se ja existir,
# so informa e segue. Exige que o App Service Plan (02) ja exista.
# =====================================================================

. "$PSScriptRoot\00-Variaveis.ps1"

Test-RecursoAz appservice,plan,show,"-n",$global:PLANO,"-g",$global:RG
Assert-ComandoOk "App Service Plan $($global:PLANO) nao existe. Rode 02-AppServicePlan.ps1 primeiro."

Test-RecursoAz webapp,show,"-n",$global:WEBAPP,"-g",$global:RG
if ($LASTEXITCODE -eq 0) {
    Write-Host "OK - Web App $($global:WEBAPP) ja existe. Nada a fazer." -ForegroundColor Green
} else {
    Write-Host ">>> Criando Web App $($global:WEBAPP)..." -ForegroundColor Cyan
    az webapp create -g $global:RG --plan $global:PLANO -n $global:WEBAPP --runtime "JAVA:21-java21" --output none
    Assert-ComandoOk "Falha ao criar o Web App $($global:WEBAPP) (o nome precisa ser globalmente unico)."
    Write-Host "OK - Web App $($global:WEBAPP) criado." -ForegroundColor Green
}
