# =====================================================================
# 98-LimparTudo.ps1
# Lista e apaga TODOS os Grupos de Recursos da assinatura atual.
#
# ATENCAO: isso remove tudo, nao apenas o KuraVet. Use quando quiser
# zerar a assinatura antes de recomecar o provisionamento do zero.
# Para apagar somente o projeto, use o 99-Cleanup.ps1.
# =====================================================================

Write-Host "Assinatura ativa:" -ForegroundColor Cyan
az account show --query "{Nome:name, Id:id}" --output table
if ($LASTEXITCODE -ne 0) {
    Write-Host "FALHA - nao foi possivel consultar a assinatura ativa (sessao nao autenticada?)." -ForegroundColor Red
    Write-Host "Corrija com: az login" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

$grupos = az group list --query "[].name" --output tsv
if ($LASTEXITCODE -ne 0) {
    Write-Host "FALHA - nao foi possivel listar os Grupos de Recursos." -ForegroundColor Red
    exit 1
}

if (-not $grupos) {
    Write-Host "Nenhum Grupo de Recursos encontrado. Nada a fazer." -ForegroundColor Green
    exit 0
}

Write-Host "Grupos de Recursos que serao APAGADOS:" -ForegroundColor Yellow
$grupos -split "`n" | ForEach-Object { Write-Host "  - $_" }
Write-Host ""

$confirma = Read-Host "Isso e IRREVERSIVEL. Digite APAGAR TUDO para confirmar"
if ($confirma -ne "APAGAR TUDO") {
    Write-Host "Operacao cancelada. Nada foi removido." -ForegroundColor Green
    exit 0
}

foreach ($g in ($grupos -split "`n")) {
    $g = $g.Trim()
    if ($g) {
        Write-Host ">>> Apagando $g ..." -ForegroundColor Yellow
        az group delete --name $g --yes --no-wait
    }
}

Write-Host ""
Write-Host ">>> Exclusoes iniciadas em segundo plano." -ForegroundColor Green
Write-Host "    Acompanhe com: az group list --output table"
Write-Host "    Pode levar alguns minutos ate a lista ficar vazia."
