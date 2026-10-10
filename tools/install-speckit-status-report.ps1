[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [ValidateSet('Test', 'Plan', 'Apply')]
    [string] $Mode = 'Plan'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Instalar somente via CLI oficial, sem executar scripts baixados como PowerShell.
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$extensionId = 'status-report'
$sourceUrl = 'https://github.com/Open-Agent-Tools/spec-kit-status/archive/refs/tags/v1.4.2.zip'
if (-not (Test-Path -LiteralPath (Join-Path $repoRoot '.git'))) {
    throw "Checkout Git nao encontrado: $repoRoot"
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'Git nao encontrado.' }

Push-Location -LiteralPath $repoRoot
try {
    & git rev-parse --show-toplevel | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'git rev-parse falhou.' }
    $specify = Get-Command specify -ErrorAction SilentlyContinue
    $initialized = (
        (Test-Path -LiteralPath (Join-Path $repoRoot '.specify\scripts')) -and
        (Test-Path -LiteralPath (Join-Path $repoRoot '.specify\templates'))
    )
    $dirty = @(& git status --porcelain=v1)
    if ($LASTEXITCODE -ne 0) { throw 'git status falhou.' }

    $installed = $false
    $installedVersion = ''
    if ($specify -and $initialized) {
        try {
            $raw = & specify extension list --json 2>$null
            if ($LASTEXITCODE -eq 0 -and $raw) {
                $existing = @(($raw -join [Environment]::NewLine | ConvertFrom-Json) |
                    Where-Object { $_.id -eq $extensionId })
                if ($existing.Count -gt 0) {
                    $installed = $true
                    $installedVersion = [string]$existing[0].version
                }
            }
        } catch {
            Write-Warning 'Nao foi possivel consultar extensoes instaladas.'
        }
    }

    [pscustomobject]@{
        Repo              = $repoRoot
        Mode              = $Mode
        GitClean          = ($dirty.Count -eq 0)
        SpecifyAvailable  = [bool]$specify
        SpecKitInitialized = $initialized
        Extension         = $extensionId
        Installed         = $installed
        InstalledVersion  = $installedVersion
        DesiredVersion    = '1.4.2'
        Source            = $sourceUrl
    } | Format-List | Out-Host

    if ($Mode -ne 'Apply') {
        Write-Host 'Test e Plan nao alteram arquivos. Consulte docs/speckit-status-report.md.'
        return
    }
    if (-not $specify) { throw 'Instale Specify CLI: uv tool install specify-cli' }
    if (-not $initialized) {
        throw 'Execute primeiro a inicializacao oficial do Spec Kit e revise o diff. Leia docs/speckit-status-report.md.'
    }
    if ($dirty.Count -gt 0) { throw 'Checkout sujo: faca commit ou stash antes de Apply.' }
    if ($installed) {
        if ($installedVersion -ne '1.4.2') {
            throw "Versao instalada: $installedVersion. Atualizacao requer revisao manual e --force."
        }
        Write-Host 'A extensao 1.4.2 ja esta instalada; nenhuma alteracao.'
        return
    }
    if (-not $PSCmdlet.ShouldProcess($repoRoot, 'Instalar extensao comunitaria Status Report 1.4.2 no Spec Kit e Codex')) {
        return
    }

    # Preserva confirmacao interativa adicional do proprio Spec Kit para URLs externas.
    & specify extension add $extensionId --from $sourceUrl
    if ($LASTEXITCODE -ne 0) { throw "Instalacao falhou com codigo $LASTEXITCODE." }
    & specify extension list
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao validar a lista de extensoes.' }
    & git status --short
}
finally {
    Pop-Location
}
