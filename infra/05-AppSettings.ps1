# =====================================================================
# 05-AppSettings.ps1
# Configura a connection string e credenciais do banco como variaveis
# de ambiente do Web App. "appsettings set" e naturalmente idempotente
# (sobrescreve os mesmos valores), mas checa os pre-requisitos antes
# de rodar. A senha nunca fica neste arquivo - veja Get-SqlPassword
# em 00-Variaveis.ps1.
# =====================================================================

. "$PSScriptRoot\00-Variaveis.ps1"

az webapp show -n $global:WEBAPP -g $global:RG --output none 2>$null
Assert-ComandoOk "Web App $($global:WEBAPP) nao existe. Rode 03-WebApp.ps1 primeiro."

az sql db show -g $global:RG --server $global:SQLSERVER -n $global:SQLDB --output none 2>$null
Assert-ComandoOk "Banco de dados $($global:SQLDB) nao existe. Rode 04-Database.ps1 primeiro."

$senha = Get-SqlPassword

Write-Host ">>> Configurando variaveis de ambiente do Web App $($global:WEBAPP)..." -ForegroundColor Cyan
az webapp config appsettings set -g $global:RG -n $global:WEBAPP --output none --settings `
    SPRING_DATASOURCE_URL="jdbc:sqlserver://$($global:SQLSERVER).database.windows.net:1433;database=$($global:SQLDB);encrypt=true;trustServerCertificate=false;loginTimeout=30;" `
    SPRING_DATASOURCE_USERNAME=$global:SQLUSER `
    SPRING_DATASOURCE_PASSWORD=$senha `
    SPRING_PROFILES_ACTIVE="azure" `
    JAVA_OPTS="-Xms128m -Xmx512m"
Assert-ComandoOk "Falha ao configurar as variaveis de ambiente do Web App $($global:WEBAPP)."
Write-Host "OK - Variaveis de ambiente configuradas." -ForegroundColor Green
