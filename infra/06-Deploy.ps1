# =====================================================================
# 06-Deploy.ps1
# Empacota e publica o .jar no Web App. Aborta se o build falhar, se o
# jar nao for gerado, ou se o deploy falhar - nunca segue silencioso.
# =====================================================================

. "$PSScriptRoot\00-Variaveis.ps1"

Test-RecursoAz webapp,show,"-n",$global:WEBAPP,"-g",$global:RG
Assert-ComandoOk "Web App $($global:WEBAPP) nao existe. Rode 03-WebApp.ps1 primeiro."

Write-Host ">>> Empacotando aplicacao (mvnw clean package)..." -ForegroundColor Cyan
& "$PSScriptRoot\..\mvnw.cmd" clean package -DskipTests
if ($LASTEXITCODE -ne 0) {
    Write-Host "FALHA - build Maven falhou (codigo de saida: $LASTEXITCODE). Deploy abortado." -ForegroundColor Red
    exit 1
}

$jar = "$PSScriptRoot\..\target\kuravet-0.0.1-SNAPSHOT.jar"
if (-not (Test-Path $jar)) {
    Write-Host "FALHA - jar nao encontrado em $jar apos o build. Deploy abortado." -ForegroundColor Red
    exit 1
}
Write-Host "OK - jar gerado em $jar." -ForegroundColor Green

Write-Host ">>> Publicando no Web App $($global:WEBAPP)..." -ForegroundColor Cyan
az webapp deploy -g $global:RG -n $global:WEBAPP --src-path $jar --type jar
Assert-ComandoOk "Falha ao publicar o jar no Web App $($global:WEBAPP)."
Write-Host "OK - Deploy concluido." -ForegroundColor Green
