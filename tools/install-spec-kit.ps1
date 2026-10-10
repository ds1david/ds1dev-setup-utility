[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [ValidateSet('Test','Plan','Apply')]
    [string] $Mode = 'Plan',
    [switch] $SkipToolInstall
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Script de inicialização LOCAL do Spec Kit, sem UAC.
# Ações de instalação estão desabilitadas até -Mode Apply + confirmação.
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if (-not (Test-Path -LiteralPath (Join-Path $repo '.git'))) {
    throw "Execute a partir de um checkout Git: $repo"
}
$git = Get-Command git -ErrorAction SilentlyContinue
if (-not $git) { throw 'Git não encontrado; instale Git primeiro.' }

Push-Location -LiteralPath $repo
try {
    & git rev-parse --is-inside-work-tree | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Não é um checkout Git válido.' }

    $dirty = @(& git status --porcelain=v1)
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao consultar git status.' }
    $uv = Get-Command uv -ErrorAction SilentlyContinue
    $specify = Get-Command specify -ErrorAction SilentlyContinue

    $summary = [ordered]@{
        Repo = $repo
        Branch = [string](& git branch --show-current)
        Clean = ($dirty.Count -eq 0)
        UvAvailable = [bool]$uv
        SpecifyAvailable = [bool]$specify
        WouldInstall = (-not $SkipToolInstall)
        Integration = 'codex'
        ScriptType = 'ps'
        Mode = $Mode
    }
    Write-Host ($summary | ConvertTo-Json -Depth 4)
    if ($Mode -ne 'Apply') { return }

    if ($dirty.Count -gt 0) {
        throw 'Checkout possui modificações. Faça commit ou stash e crie uma branch dedicada antes de -Mode Apply.'
    }
    if (-not $SkipToolInstall -and -not $uv) {
        throw 'uv não encontrado; instale o gerenciador uv por canal oficial ou use -SkipToolInstall com specify já instalado.'
    }
    if (-not $uv -and -not $specify) {
        throw 'Nem uv nem specify disponível.'
    }

    if (-not $PSCmdlet.ShouldProcess($repo, 'Instalar CLI Spec Kit (opcional) e gerar skills/scripts oficiais no checkout')) {
        return
    }

    if (-not $SkipToolInstall) {
        & uv tool install specify-cli
        if ($LASTEXITCODE -ne 0) { throw "uv tool install specify-cli falhou com exit code $LASTEXITCODE" }
    }

    # O PATH da sessão pode ainda não expor uma instalação recém-realizada.
    $cmd = Get-Command specify -ErrorAction SilentlyContinue
    if (-not $cmd) {
        throw 'O specify foi instalado mas ainda não é encontrado no PATH. Abra nova sessão e execute com -SkipToolInstall.'
    }

    & specify init --here --force --non-interactive --integration codex --script ps
    if ($LASTEXITCODE -ne 0) { throw "specify init falhou com exit code $LASTEXITCODE" }

    Write-Host 'Inicialização gerada. Revise git status e git diff antes de versionar.'
    & git status --short
}
finally {
    Pop-Location
}
