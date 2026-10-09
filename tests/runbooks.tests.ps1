#requires -Version 7
# Sem Pester ou módulos externos; não altera instalações do host.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '../src/Runbooks.psm1') -Force
$root = Join-Path ([IO.Path]::GetTempPath()) ('ds1-runbooks-test-' + [guid]::NewGuid().ToString('N'))
$script:checks = 0
function Assert([bool]$Condition,[string]$Message) {
    if (-not $Condition) { throw "FAIL: $Message" }
    $script:checks++
}
function Assert-Throws([scriptblock]$Action,[string]$Pattern) {
    $caught = $null
    try { & $Action | Out-Null } catch { $caught = $_.Exception.Message }
    Assert ($null -ne $caught -and $caught -match $Pattern) "Exceção esperada: $Pattern; recebido: $caught"
}
function Add-Fixture([string]$Id,[string]$Dependencies='',[bool]$Detected=$true) {
    $directory = Join-Path $root $Id
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
    $manifest = "@{SchemaVersion=1;Id='$Id';Title='$Id';Environment='Windows';DependsOn=@($Dependencies);Script='runbook.ps1';Implemented=`$true;SupportsVersions=`$true}"
    Set-Content -LiteralPath (Join-Path $directory 'runbook.psd1') -Value $manifest
    $detectedText = if ($Detected) { '$true' } else { '$false' }
    $handler = @'
param($Mode,$Version,$Context)
if ($Mode -eq 'Test') { return @{Succeeded=$true;Detected=DETECTED} }
if ($Mode -eq 'Apply') { Set-Content -LiteralPath $Context.Marker -Value $Version }
return @{Succeeded=$true}
'@.Replace('DETECTED',$detectedText)
    Set-Content -LiteralPath (Join-Path $directory 'runbook.ps1') -Value $handler
}
try {
    New-Item -ItemType Directory -Path $root | Out-Null
    Add-Fixture base
    $catalog = @(Get-RunbookCatalog $root)
    Assert ($catalog.Count -eq 1) 'descobrir primeiro runbook'
    Add-Fixture extra "'base'"
    $catalog = @(Get-RunbookCatalog $root)
    Assert ($catalog.Count -eq 2) 'descobrir runbook novo sem alterar executor ou catálogo central'
    $extra = $catalog | Where-Object Id -eq extra
    Test-RunbookDependencies $extra $catalog
    $marker = Join-Path $root 'applied.txt'
    Invoke-RunbookHandler $extra Apply '21.0.6' @{Marker=$marker} | Out-Null
    Assert ((Get-Content $marker) -eq '21.0.6') 'encaminhar versão e executar handler novo'
    Add-Fixture base '' $false
    Assert-Throws { Test-RunbookDependencies $extra $catalog } 'Dependência não satisfeita'
    Add-Fixture base "'extra'"
    Assert-Throws { Get-RunbookCatalog $root } 'Ciclo'
    Add-Fixture base "'inexistente'"
    Assert-Throws { Get-RunbookCatalog $root } 'Dependência desconhecida'
    Add-Fixture base
    Add-Fixture duplicate
    $duplicate = Join-Path $root 'duplicate/runbook.psd1'
    (Get-Content $duplicate -Raw).Replace("Id='duplicate'", "Id='base'") | Set-Content $duplicate
    Assert-Throws { Get-RunbookCatalog $root } 'Id duplicado'
    Remove-Item (Join-Path $root duplicate) -Recurse -Force
    $manifest = Join-Path $root 'extra/runbook.psd1'
    (Get-Content $manifest -Raw).Replace("Script='runbook.ps1'", "Script='../base/runbook.ps1'") | Set-Content $manifest
    Assert-Throws { Get-RunbookCatalog $root } 'Script inválido'
    Add-Fixture extra "'base'"
    $catalog = @(Get-RunbookCatalog $root)
    $extra = $catalog | Where-Object Id -eq extra
    $extra.Implemented = $false
    Assert-Throws { Invoke-RunbookHandler $extra Apply } 'não implementada'
    $extra.SupportsVersions = $false
    Assert-Throws { Invoke-RunbookHandler $extra Test '21' } 'versão explícita'
    $extra.SupportsVersions = $true
    Set-Content $extra.ScriptPath -Value 'param($Mode,$Version,$Context); return @{Succeeded=$true}'
    Assert-Throws { Invoke-RunbookHandler $extra Test } 'Detected'
    Set-Content $extra.ScriptPath -Value 'param($Mode,$Version,$Context); return @{Succeeded=$false}'
    Assert-Throws { Invoke-RunbookHandler $extra Plan } 'Runbook falhou'
    $production = @(Get-RunbookCatalog (Join-Path $PSScriptRoot '../runbooks'))
    Assert ($production.Count -eq 10) 'migrar as dez tarefas existentes'
    foreach ($file in Get-ChildItem (Join-Path $PSScriptRoot '..') -Recurse -File | Where-Object Extension -in '.ps1','.psm1','.psd1') {
        $tokens = $null; $parseErrors = $null
        $null = [Management.Automation.Language.Parser]::ParseFile($file.FullName,[ref]$tokens,[ref]$parseErrors)
        Assert ($parseErrors.Count -eq 0) "sintaxe: $($file.FullName)"
    }
    Write-Host "PASS: $script:checks verificações"
} finally { Remove-Item -LiteralPath $root -Recurse -Force }
