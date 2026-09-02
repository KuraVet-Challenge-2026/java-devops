# =====================================================================
# 00-Variaveis.ps1
# Variaveis e funcoes centrais do provisionamento.
#
# Uso: sempre via dot-sourcing, no topo de cada script:
#   . "$PSScriptRoot\00-Variaveis.ps1"
#
# Todas as variaveis e funcoes usam escopo $global:/function:global:
# de proposito: dot-sourcing normalmente cria variaveis no escopo do
# CALLER (script que chamou), mas usar $global: explicitamente garante
# que elas fiquem visiveis mesmo se este arquivo for chamado de formas
# diferentes (dot-source direto, dentro de uma funcao, etc.), evitando
# o classico bug de "variavel nao definida" em scripts de PowerShell.
# =====================================================================

# ---------------------------------------------------------------------
# Assinatura esperada (checada pelo 00-Preflight.ps1)
# Preencha o Id real da assinatura com: az account show --query id -o tsv
# Enquanto ficar com o valor placeholder abaixo, o Preflight apenas
# avisa (nao aborta), porque nao ha como validar um Id que nao existe.
# ---------------------------------------------------------------------
$global:AssinaturaEsperadaId   = "23310d92-c990-4fea-9fce-9b2416c4cf9b"
$global:AssinaturaEsperadaNome = "" # opcional, so para exibicao

# ---------------------------------------------------------------------
# Recursos do projeto
# ---------------------------------------------------------------------
$global:RG        = "rg-kuravet-rm563620"
$global:LOCAL     = "mexicocentral"
$global:PLANO     = "plan-kuravet-rm563620"
$global:SKU       = "B1"
$global:WEBAPP    = "kuravet-rm563620"
$global:SQLSERVER = "sqlserver-kuravet-rm563620"
$global:SQLDB     = "bd_kuravet"
$global:SQLUSER   = "kuravetadmin"

# ---------------------------------------------------------------------
# Senha do administrador do SQL Server
# NUNCA em texto plano neste arquivo (ele e versionado no git).
#
# Get-SqlPassword() resolve a senha, em ordem de preferencia:
#   1) variavel de ambiente SQLADMIN_PASSWORD (nao versionada, definida
#      pelo usuario antes de rodar os scripts: $env:SQLADMIN_PASSWORD = "...")
#   2) prompt interativo com Read-Host -AsSecureString (nao aparece na
#      tela nem fica no historico do shell)
#
# So e chamada pelos scripts que realmente precisam da senha (04 e 05),
# e so uma vez por sessao (cacheada em $global:SQLPASS).
# ---------------------------------------------------------------------
function global:Get-SqlPassword {
    if (-not $global:SQLPASS) {
        if ($env:SQLADMIN_PASSWORD) {
            $global:SQLPASS = $env:SQLADMIN_PASSWORD
        } else {
            $senhaSegura = Read-Host -Prompt "Senha do administrador do SQL Server (nao sera exibida nem gravada)" -AsSecureString
            $global:SQLPASS = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
                [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($senhaSegura)
            )
        }
    }
    return $global:SQLPASS
}

# ---------------------------------------------------------------------
# Assert-ComandoOk
# az e um executavel externo: quando falha, NAO lanca excecao do
# PowerShell (por isso $ErrorActionPreference = "Stop" nao o pega).
# Ele sinaliza erro escrevendo em stderr e retornando exit code != 0,
# refletido em $LASTEXITCODE logo apos a chamada. Toda chamada az nos
# scripts 01-06 e 99 deve ser seguida por Assert-ComandoOk, que aborta
# o script (exit 1) imediatamente se o comando anterior falhou -
# impedindo que passos seguintes rodem sobre um estado invalido e
# produzam erros derivados que escondem a causa raiz.
# ---------------------------------------------------------------------
# ---------------------------------------------------------------------
# Test-RecursoAz
# Checa se um recurso existe rodando "az <Argumentos> --output none".
# Ao final, deixa $LASTEXITCODE em 0 (achou) ou nao-zero (nao achou),
# para ser usado com Assert-ComandoOk logo em seguida - por isso NAO
# retorna valor, so tem efeito colateral no $LASTEXITCODE.
#
# Por que existe (substitui "az ... --output none 2>$null" usado antes
# direto nos scripts):
#   1) No Windows PowerShell 5.1, redirecionar o stderr de um
#      executavel nativo com "2>" pode alterar $LASTEXITCODE mesmo
#      quando o comando teve sucesso - um bug conhecido do PowerShell
#      com wrappers .cmd como o az. "2>&1 | Out-Null" nao tem esse
#      problema e continua suprimindo a mensagem de erro do az no
#      console.
#   2) Um recurso recem-criado pode nao aparecer imediatamente em
#      consultas seguintes (consistencia eventual do Azure Resource
#      Manager). Por isso tenta ate 3x com pausa antes de considerar
#      que o recurso realmente nao existe.
# ---------------------------------------------------------------------
function global:Test-RecursoAz {
    param(
        [Parameter(Mandatory = $true)][string[]]$Argumentos
    )
    for ($tentativa = 1; $tentativa -le 3; $tentativa++) {
        az @Argumentos --output none 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { return }
        if ($tentativa -lt 3) { Start-Sleep -Seconds 3 }
    }
}

function global:Assert-ComandoOk {
    param(
        [Parameter(Mandatory = $true)][string]$Mensagem
    )
    if ($LASTEXITCODE -ne 0) {
        Write-Host "FALHA - $Mensagem (codigo de saida: $LASTEXITCODE)" -ForegroundColor Red
        Write-Host "Script abortado para nao propagar o erro. Corrija a causa acima e rode novamente." -ForegroundColor Red
        exit 1
    }
}
