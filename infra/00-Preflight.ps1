# =====================================================================
# 00-Preflight.ps1
# Validacoes de ambiente a rodar ANTES de 01-06. Nao cria nenhum
# recurso permanente do projeto - so testes descartaveis.
#
# Cada checagem imprime OK ou FALHA com a causa e o comando de
# correcao. Se qualquer checagem falhar, o script termina com
# exit 1, para o aluno corrigir antes de gastar tempo rodando
# 01-06 contra um ambiente que vai falhar no meio do caminho.
#
# Uso:
#   .\00-Preflight.ps1
# =====================================================================

. "$PSScriptRoot\00-Variaveis.ps1"

$global:PreflightFalhou = $false

function Escreve-Titulo($titulo) {
    Write-Host ""
    Write-Host ">>> $titulo" -ForegroundColor Cyan
}

function Escreve-Ok($msg) {
    Write-Host "  OK - $msg" -ForegroundColor Green
}

function Escreve-Falha($causa, $correcao) {
    Write-Host "  FALHA - $causa" -ForegroundColor Red
    Write-Host "  Corrija com: $correcao" -ForegroundColor Yellow
    $global:PreflightFalhou = $true
}

# ---------------------------------------------------------------------
# 1) Assinatura ativa
# ---------------------------------------------------------------------
Escreve-Titulo "1. Assinatura ativa"
$contaJson = az account show --output json 2>$null
if ($LASTEXITCODE -ne 0 -or -not $contaJson) {
    Escreve-Falha "Nao foi possivel consultar a assinatura ativa (sessao nao autenticada)." "az login"
} else {
    $conta = $contaJson | ConvertFrom-Json
    Write-Host "  Assinatura atual: $($conta.name)  ($($conta.id))"
    if ($global:AssinaturaEsperadaId -and $global:AssinaturaEsperadaId -ne "23310d92-c990-4fea-9fce-9b2416c4cf9b") {
        if ($conta.id -eq $global:AssinaturaEsperadaId) {
            Escreve-Ok "Assinatura ativa confere com a esperada."
        } else {
            Escreve-Falha "Assinatura ativa ($($conta.id)) e diferente da esperada ($($global:AssinaturaEsperadaId))." "az account set --subscription $($global:AssinaturaEsperadaId)"
        }
    } else {
        Write-Host "  AVISO: `$global:AssinaturaEsperadaId nao foi preenchida em 00-Variaveis.ps1 - checagem pulada." -ForegroundColor Yellow
        Write-Host "  Preencha com o Id mostrado acima se ele for o correto (az account show --query id -o tsv)." -ForegroundColor Yellow
    }
}

# ---------------------------------------------------------------------
# 2) Registro dos provedores de recursos
# ---------------------------------------------------------------------
Escreve-Titulo "2. Provedores de recursos (Microsoft.Web / Microsoft.Sql)"
foreach ($provedor in @("Microsoft.Web", "Microsoft.Sql")) {
    $estado = az provider show --namespace $provedor --query "registrationState" --output tsv 2>$null
    if ($LASTEXITCODE -ne 0) {
        Escreve-Falha "Nao foi possivel consultar o provedor $provedor." "az provider register --namespace $provedor --wait"
        continue
    }
    if ($estado -eq "Registered") {
        Escreve-Ok "$provedor registrado."
    } else {
        Escreve-Falha "$provedor esta '$estado' (esperado 'Registered')." "az provider register --namespace $provedor --wait"
    }
}

# ---------------------------------------------------------------------
# 3) Disponibilidade real do SKU do App Service Plan na regiao
# (cobre o sintoma "Current Limit (F1 VMs): 0" - isso e cota da
# assinatura na regiao, so aparece tentando criar de verdade).
# Cria e apaga um Resource Group + Plano DESCARTAVEIS, distintos dos
# recursos definitivos do projeto (que 01/02 criam).
# ---------------------------------------------------------------------
Escreve-Titulo "3. Disponibilidade real do SKU $($global:SKU) (App Service Plan Linux) em $($global:LOCAL)"
$rgTeste    = "$($global:RG)-preflight-tmp"
$planoTeste = "$($global:PLANO)-preflight-tmp"

az group create -n $rgTeste -l $global:LOCAL --output none 2>$null
if ($LASTEXITCODE -ne 0) {
    Escreve-Falha "Nao foi possivel criar o Resource Group temporario ($rgTeste) para o teste de SKU." "az group create -n $rgTeste -l $($global:LOCAL)"
} else {
    $saidaPlano = az appservice plan create -n $planoTeste -g $rgTeste --is-linux --sku $global:SKU --location $global:LOCAL --output none 2>&1
    if ($LASTEXITCODE -eq 0) {
        Escreve-Ok "SKU $($global:SKU) disponivel em $($global:LOCAL) (cota confirmada)."
        az appservice plan delete -n $planoTeste -g $rgTeste --yes --output none 2>$null
    } else {
        Escreve-Falha "SKU $($global:SKU) indisponivel/sem cota em $($global:LOCAL): $saidaPlano" "Troque `$global:SKU em 00-Variaveis.ps1 (ex.: B1) ou peca aumento de cota: portal Azure > Ajuda + Suporte > Nova solicitacao > Cotas"
    }
    az group delete -n $rgTeste --yes --no-wait --output none 2>$null
}

# ---------------------------------------------------------------------
# 4) Capacidade da regiao para SQL Server
# (cobre o sintoma "RegionDoesNotAllowProvisioning" - a assinatura
# so pode provisionar Microsoft.Sql/servers nas regioes listadas
# pelo proprio provedor; checagem leve, sem criar servidor nenhum).
# ---------------------------------------------------------------------
Escreve-Titulo "4. Capacidade da regiao $($global:LOCAL) para Microsoft.Sql/servers"
$locaisJson = az provider show --namespace Microsoft.Sql --query "resourceTypes[?resourceType=='servers'].locations | [0]" --output json 2>$null
if ($LASTEXITCODE -ne 0 -or -not $locaisJson) {
    Escreve-Falha "Nao foi possivel consultar as regioes habilitadas para Microsoft.Sql/servers." "az provider show --namespace Microsoft.Sql --query `"resourceTypes[?resourceType=='servers'].locations`" --output table"
} else {
    $listaLocais = ($locaisJson | ConvertFrom-Json) | ForEach-Object { $_ -replace '\s', '' }
    $localAlvo = $global:LOCAL -replace '\s', ''
    if ($listaLocais -contains $localAlvo) {
        Escreve-Ok "Regiao $($global:LOCAL) habilitada para Microsoft.Sql/servers nesta assinatura."
    } else {
        Escreve-Falha "Regiao $($global:LOCAL) NAO esta habilitada para SQL Server nesta assinatura." "Escolha uma regiao da lista: az provider show --namespace Microsoft.Sql --query `"resourceTypes[?resourceType=='servers'].locations`" --output table"
    }
}

# ---------------------------------------------------------------------
# Resultado final
# ---------------------------------------------------------------------
Write-Host ""
if ($global:PreflightFalhou) {
    Write-Host "======================================================================" -ForegroundColor Red
    Write-Host "PREFLIGHT FALHOU. Corrija os itens marcados FALHA antes de rodar 01-06." -ForegroundColor Red
    Write-Host "======================================================================" -ForegroundColor Red
    exit 1
} else {
    Write-Host "======================================================================" -ForegroundColor Green
    Write-Host "PREFLIGHT OK. Ambiente valido para provisionar 01-06." -ForegroundColor Green
    Write-Host "======================================================================" -ForegroundColor Green
    exit 0
}
