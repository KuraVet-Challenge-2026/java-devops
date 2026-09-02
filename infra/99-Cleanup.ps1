# =====================================================================
# 99-Cleanup.ps1
# Remove toda a infraestrutura criada (apaga o Resource Group inteiro).
# Execute SOMENTE apos a gravacao do video e a correcao do professor.
# =====================================================================

. "$PSScriptRoot\00-Variaveis.ps1"

$existe = az group exists -n $global:RG
if ($existe -ne "true") {
    Write-Host "OK - Resource Group $($global:RG) nao existe. Nada a apagar." -ForegroundColor Green
    exit 0
}

$confirma = Read-Host "Confirma a exclusao do Resource Group $($global:RG)? (digite SIM)"
if ($confirma -ne "SIM") {
    Write-Host "Operacao cancelada."
    exit 0
}

az group delete --name $global:RG --yes --no-wait
Assert-ComandoOk "Falha ao solicitar a exclusao do Resource Group $($global:RG)."
Write-Host ">>> Exclusao iniciada em segundo plano." -ForegroundColor Green
